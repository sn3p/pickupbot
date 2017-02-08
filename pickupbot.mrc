/*
*  -----------------------------
*  Pickupbot v 1.6d
*  By MoehMan
*  http://www.moehman.nl
*  Have fun!
*  -----------------------------
*/

/* 
-- CONFIG -- 
*/

alias pb.getserver {
  ;change this to switch server
  return irc.quakenet.org:6667
}

alias pb.getchannel {
  ;change this to your channel
  ;if you use a password, just put it after the channel (e.g. #channel password)
  return #channel
}

alias pb.useadminchan {
  ;you can enable this to have an adminchannel, in which you can use bans and look up bans only
  return $true
  ;if you set this to $true, dont forget to edit the alias below (to set an adminchannel)
}

alias pb.adminchan {
  ;adminchannel, for ban management
  return #channel.admin
}

alias pb.style.chan1 {
  return 0,14
}
alias pb.style.chan2 {
  return 1,15
}
alias pb.style.chan3 {
  return 0,3
}
alias pb.style.players {
  return 
}
alias pb.style.promote {
  ;the character &players is replaced by the number of players
  return &players player(s) needed for a UT99 iCTF ZP pickup war @ $pb.channel
}

alias pb.channel.autovoice {
  ;if every user is voiced, default $false
  return $false
}

alias pb.channel.voice {
  ;if a player which will play will be voiced
  return $true
}

alias pb.auth {
  ;you can enter the AUTH data here, for authing on quakenet
  ;msg Q@cserve.quakenet.org AUTH name password
  ;uncomment this line to use it.
}

alias pb.players {
  ;maximum number of players, for 5on5 this is 10, for 2on2 it is 4 etc.
  return 4
}

alias pb.time {
  ;total time of 1 game, in seconds.
  return 3000
  ; 3000=50 mins, 2x20mins + some 'connection' time
}

alias pb.serverline {
  ;use &team (returns: RED/BLUE) for the team.
  ;use &captain (returns: YES/NO) to say if somebody is a teamcaptain (BUGGED, please don't use)
  ;feel free to modify this line so it suits your needs:)
  return The pickup game is starting, go to the server and have fun:) - Server ip: xxxx password: xxxx - TS: xxxx pass: xxxx - Team: &team
}

alias pb.playing {
  ;change this line if you want
  ;use &time to refer to the number of minutes + seconds left
  return A pickup game is being played right now. (&time remaining)
}

alias pb.reporter {
  ;this line is used to spam a reporter channel
  return Reporter in #reporter
}

alias pb.allowteams {
  ;NEW IN 1.6D
  ;set this to $false to enable forces random teams, so people cannot vote!
  ; $true = people can add to a team.
  return $true
}


/* ----------------------------------
*  -- STOP CHANGING ANYTHING HERE. --
*  -- The bot may stop working correctly if you change anything below --
* ----------------------------------
*/

alias pb.channel {
  return $pb.getchannel
}

alias pb.credits {
  return 07[4- 14P07ickupbot 14v07ersion $pb.version 4- 14b07y 14M07oeh14M07an 4- 07www.moehman.nl 4-07]
}

alias pb.version {
  return 1.6d
}

; -- PICKUP FUNCTIONS -- 

alias -l pb.init {
  ;init bot
  set %pb.active $true
  hmake pb.users 10 ;create hash table, for users
  hmake pb.maps 10 ;create hash table for maps,load from file
  hmake pb 20 ;misc table
  hmake pb.hist 200 ;history, players with their host
  hmake pb.bans 10
  hadd pb pickup 0
  pb.getmaps
  pb.load
  .timer 0 120 pb.save
  server $pb.getserver
  return 1
  :error
  echo -s PICKUPBOT ERROR: $error
  reseterror
  return 0
}

/*

Hash tables:
pb.users:
1 nickname
1.voted 0    <- 0=no 1=yes
1.captain 0  <- 0=no 1=yes
1.team 1     <- 0=random 1=red 2=blue
1.voted 3    <- number of map he/she voted for, 0 = none
...

pb.maps:
1 Extortion
2 Gauntlet
....

pb.vote:
Extortion 2
Gauntlet 0
...

pb:
pickup unixtime/0 <- if a game is beeing played, unixtime at end time. If not: 0
number 10 <- number of pickups played, if you want to set this, use: /hadd pb number xxxx

pb.hist:
nickname identd@host.ext

*/

alias pb.reset {
  ;reset the bot
  hfree pb.users
  hmake pb.users 10
  hdel -w pb.maps *
  hadd pb pickup 0
  pb.getmaps
}

alias pb.save {
  ;save all
  hsave pb.maps pickup.maps.txt
  hsave pb.hist pickup.hist.txt
  hsave pb pickup.misc.txt
  hsave pb.bans pickup.bans.txt
}

alias pb.load {
  if ($isfile(pickup.misc.txt) == $true) {
    hload pb pickup.misc.txt
  }
  if ($isfile(pickup.hist.txt) == $true) {
    hload pb.hist pickup.hist.txt
  }
  if ($isfile(pickup.bans.txt) == $true) {
    hload pb.bans pickup.bans.txt
  }

}

alias pb.done {
  if ($pb.channel.voice == $true) {
    pb.devoiceall
  }
  pb.reset
  unset %pb.game*
  msg $pb.channel You can sign up again!
  timer$done off
}

alias -l pb.savepickup {
  ; $1 = lognumber
  hmake pb.log
  ;save this pickup
  hadd pb.log number %number
  set %n 0
  set %m 1
  set %player 1
  while (%m <= $pb.players && %player != $null) {
    set %player $hget(pb.users,%m)
    if (%player != $null) {
      hadd pb.log p $$+ %m %player
      hadd pb.log ph $$+ %m $hget(pb.hist,%player)
      hadd pb.log pt $$+ %m $hget(pb.users,%m $$+ .team)
      hadd pb.log pc $$+ %m $hget(pb.users,%m $$+ .captain)
    }
    inc %m
  }
  hsave pb.log pickuplog. $$+ %number $$+ .txt
  hfree pb.log
}

alias -l pb.voiceall {
  if ($pb.channel.voice == $true) {
    set %n 0
    set %m 1
    set %player 1
    set %voiced 0
    set %voicedppl $null
    while (%m <= $pb.players && %player != $null) {
      set %player $hget(pb.users,%m)
      if (%voiced >= 5) {
        mode $pb.channel +vvvvv %voicedppl
        set %voicedppl $null
        set %voiced 0
      }
      set %voicedppl %voicedppl %player
      inc %voiced
      inc %m
    }
    if (%voiced != 0) {
      mode $pb.channel +vvvvv %voicedppl
    }
  }
}

alias -l pb.devoiceall {
  if ($pb.channel.voice == $true) {
    set %n 0
    set %m 1
    set %player 1
    set %voiced 0
    set %voicedppl $null
    while (%m <= $pb.players && %player != $null) {
      set %player $hget(pb.users,%m)
      if (%voiced >= 5) {
        mode $pb.channel -vvvvv %voicedppl
        set %voicedppl $null
        set %voiced 0
      }
      set %voicedppl %voicedppl %player
      inc %voiced
      inc %m
    }
    if (%voiced != 0) {
      mode $pb.channel -vvvvv %voicedppl
    }
  }
}


alias -l pb.getmaps {
  ;get from file
  if ($isfile(pickup.maps.txt) == $true) {
    hload pb.maps pickup.maps.txt
  }
}

alias -l pb.addmap {
  set %i 100
  set %n 1
  while (%n <= %i) {
    set %pb.map $hget(pb.maps,%n)
    if (%pb.map == $1) {
      return %n
    }
    if (%pb.map == $null) { 
      break
    }
    inc %n
  }
  hadd pb.maps %n $1
}

alias -l pb.delmap {
  set %map $pb.findmap($1)
  if (%map != 0) {
    hdel pb.maps %map
    unset %map
  }
}

alias -l pb.findmap {
  ;$1 = map
  set %i 100
  set %n 1
  while (%n <= %i) {
    set %pb.map $hget(pb.maps,%n)
    if (%pb.map == $1) {
      return %n
    }
    inc %n
  }
  return 0
}

alias -l pb.addvote {
  ;$1map $2nickname
  ;map exists
  unset %pb.maps
  if ($pb.isuser($2) == $false) { return $false }
  set %pb.votemap $pb.findmap($1)
  if (%pb.votemap == 0) {
    ;map does not exist
    msg $pb.getchannel Allowed maps: $pb.getmaplist
  }
  else {
    hadd pb.users $pb.getuser($2) $$+ .voted %pb.votemap
    notice $2 You voted for $1
  }
}

alias -l pb.getmaplist {
  unset %pb.maps
  set %i 100
  set %n 1
  while (%n <= %i) {
    set %pb.map $hget(pb.maps,%n)
    if (%pb.map != $null) {
      set %pb.map.votes $pb.getmapvotes(%n)
      set %pb.maps %pb.maps $$+  $pb.style.chan [ $+ [ $calc( ( %n % 3 ) + 1 ) ] ] $$+ %pb.map $$+ ( $$+ %pb.map.votes $$+ )
    }
    inc %n
  }
  return %pb.maps
}

alias -l pb.findvotewinner {
  set %curmap $null
  set %curmapvotes -1
  set %i 100
  set %n 1
  while (%n <= %i) {
    set %pb.map $hget(pb.maps,%n)
    set %map $pb.getmapvotes(%n)
    if (%map > %curmapvotes) {
      set %curmap %pb.map
      set %curmapvotes %map
    }
    inc %n
  }
  return %curmap
}

alias -l pb.getmapvotes {
  ; $1 = mapnumber
  set %m 1
  set %player 1
  set %votes 0
  while (%m <= $pb.players) {
    set %player $hget(pb.users,%m)
    if (%player != $null) {
      if ($hget(pb.users,%m $$+ .voted) == $1) {
        inc %votes
      }
    }
    inc %m
  }
  return %votes
}

alias -l pb.isuser {
  set %m 1
  set %player 1
  while (%m <= $pb.players) {
    set %player $hget(pb.users,%m)
    if (%player == $1) {
      return $true
    }
    inc %m
  }
  ;player not added
  return $false
}

alias -l pb.getuser {
  set %n 0
  set %m 1
  set %player 1
  while (%m <= $pb.players) {
    set %player $hget(pb.users,%m)
    if (%player == $1) {
      return %m
    }
    inc %m
  }
  ;player not added
  return $false
}

alias -l pb.adduser {
  ; $1=nickname $2=*!identd@host $3=$null/red/blue
  set %number $hget(pb,pickup)
  if (%number > 0) {
    msg $pb.channel $replace($pb.playing,&time,$asctime($calc(%number - $ctime),nn:ss))
    return 0
  }
  if ($pb.isuser($1) == $true) {
    halt
  }

  set %m 1
  set %player 1
  while (%m <= $pb.players) {
    set %player $hget(pb.users,%m)
    if (%player == $null) {
      break
    }
    inc %m
  }
  ;player not added
  unset %tmp
  set %tmp %m $$+ .team
  hadd pb.users %m $1
  hadd pb.users %m $$+ .voted 0
  hadd pb.users %m $$+ .captain 0
  if ($3 == red && $pb.allowteams) {
    hadd pb.users %tmp 1
  }
  elseif ($3 == blue && $pb.allowteams) {
    hadd pb.users %tmp 2
  }
  else {
    hadd pb.users %tmp 0
  }
  if ($pb.channel.voice == $true ) {
    mode $pb.channel +v $1
  }
  hadd pb.hist $1 $2
  ;add user to history
  notice $1 You are added! Please vote for your favorite map (!vote mapname)
  if ($pb.players != $pb.getnumplayers) {
    pb.usermsg
  }
  pb.checkgo
}

alias -l pb.deluser {
  set %n 1
  set %m 1
  while (%m < $pb.players) {
    set %player $hget(pb.users,%m)
    if (%player == $1) {
      if ($pb.channel.voice == $true ) {
        mode $pb.channel -v $1
      }
      hdel -w pb.users %m $$+ *
      pb.usermsg
      return 1
    }
    inc %m
  }
}

alias -l pb.isrunning {
  set %number $hget(pb,pickup)
  if (%number > 0) {
    return $true
  }
  else {
    return $false
  }
}

alias -l pb.getnumplayers {
  ;number of players avail
  set %m 1
  set %player 1
  set %players 0
  while (%m <= $pb.players) {
    set %player $hget(pb.users,%m)
    if (%player != $null) {
      inc %Players
    }
    inc %m
  }
  return %players
}

alias -l pb.getplayers {
  ;listing of all players avail
  set %m 1
  unset %players
  while (%m <= $pb.players) {
    set %pteam $hget(pb.users,%m $$+ .team)
    if (%pteam == 0) {
      set %players %players 14 $$+ $hget(pb.users,%m) $$+ 
    }
    if (%pteam == 1) {
      set %players %players 4 $$+ $hget(pb.users,%m) $$+ 
    }
    if (%pteam == 2) {
      set %players %players 12 $$+ $hget(pb.users,%m) $$+ 
    }
    inc %m
  }
  return %players
}

alias -l pb.getcaptain {
  ;$1=red/blue
  if ($1 == blue) {
    return %blue.captain
  }
  elseif ($1 == red) {
    return %red.captain
  }
}
alias -l pb.redteam {
  set %n 1
  set %m 1
  unset %player
  unset %players
  while (%m <= $pb.players) {
    set %playerteam $hget(pb.users,%m $$+ .team )
    set %player $hget(pb.users,%m)
    if (%playerteam == 1) {
      set %players %players %player
    }
    inc %m
  }
  return %players
}

alias -l pb.blueteam {
  set %n 1
  set %m 1
  unset %player
  unset %players
  while (%m <= $pb.players) {
    set %playerteam $hget(pb.users,%m $$+ .team )
    set %player $hget(pb.users,%m)
    if (%playerteam == 2) {
      set %players %players %player
    }
    inc %m
  }
  return %players
}

alias -l pb.maketeams {
  ;this alias is copied from version 1.8e5
  ;verdeel spelers
  ;check for too large teams
  ;make captain
  var %red.players = 0
  var %blue.players = 0
  var %red = $null
  var %blue = $null
  set %red.captain 0
  set %blue.captain 0
  var %ppt = $calc($pb.players / 2)
  var %m = 1
  while (%m <= $pb.players) {
    var %cplayer = $hget(pb.users,%m )
    var %cplayert = $hget(pb.users,%m $$+ .team )
    var %cplayerc = $hget(pb.users,%m $$+ .captain )
    if ($pb.allowteams == $false) {
      var %cplayert = 0
      ;choose a random team :)
    }
    if (%cplayert == 1) {
      if (%red.players >= %ppt) {
        ;make him blue
        %blue = %blue %m
        hadd pb.users %m $$+ .team 2
        inc %blue.players
      }
      else {
        ;ok join red
        %red = %red %m
        inc %red.players
      }
      if (%cplayerc == 1 && %red.captain != 0) {
        set %red.captain %cplayer
        hadd pb.users %m $$+ .captain 1
      }
    }
    elseif (%cplayert == 2) {
      if (%blue.players >= %ppt) {
        ;make him red
        %red = %red %m
        hadd pb.users %m $$+ .team 1
        inc %red.players
      }
      else {
        ;ok join blue
        %blue = %blue %m
        inc %blue.players
      }
      if (%cplayerc == 1 && %blue.captain != 0) {
        %blue.captain = %cplayer
        hadd pb.users %m $$+ .captain 1
      }
    }
    inc %m
  }
  ;end, force ppl in a team, if they arent
  if (%red.players != %ppt || %blue.players != %ppt) {
    var %rndt = $null
    var %m = 1
    while (%m <= $pb.players) {
      set %cplayer $hget(pb.users,%m)
      set %cplayert $hget(pb.users,%m $$+ .team )
      set %cplayerc $hget(pb.users,%m $$+ .captain )
      if (%cplayert == 0) {
        %rndt = $rand(1,2)
        if (%rndt == 1 && %red.players < %ppt) {
          %tmp = %m $$+ .team
          %red = %red %m
          hadd pb.users %tmp 1
          inc %red.players
        }
        elseif ((%rndt == 2 && %blue.players < %ppt) || (%rndt == 1 && %red.players == %ppt)) {
          %tmp = %m $$+ .team
          %blue = %blue %m
          hadd pb.users %tmp 2
          inc %blue.players
        }
        else {
          ;add them to red...
          %tmp = %m $$+ .team
          %red = %red %m
          hadd pb.users %tmp 1
          inc %red.players
        }
      }
      inc %m
    }
  }
  if (%red.captain == 0) {
    ;select a random red captain
    var %p = $rand(1,%ppt)
    set %red.captain $hget(pb.users,$gettok(%red,%p,32))
    hadd pb.users %p $$+ .captain 1
    echo 4 -s captain red: %p %red.captain
  }
  if (%blue.captain == 0) {
    ;select a random blue captain
    %p = $rand(1,%ppt)
    set %blue.captain $hget(pb.users,$gettok(%blue,%p,32))
    hadd pb.users %p $$+ .captain 1
    echo 4 -s captain red: %p %red.captain
  }
  ;pff finaly, we have all players signed up, and every team has a captain.
  ;now GOGOGO
}

alias pb.checkgo {
  ;check if the pickup can start
  if ($pb.players == $pb.getnumplayers) {
    ;start
    hadd pb pickup $calc($ctime + $pb.time)
    set %number $hget(pb,number)
    inc %number
    hadd pb number %number
    pb.maketeams
    pb.savepickup
    .timer 1 0 msg $pb.channel Pickup game number %number is starting now!
    .timer 1 2 msg $pb.channel 4Red Team: Captain:  $$+ $pb.getcaptain(red) $$+  Players: $pb.redteam
    .timer 1 2 msg $pb.channel 12Blue Team: Captain:  $$+ $pb.getcaptain(blue) $$+  Players: $pb.blueteam
    .timer 1 3 msg $pb.channel Map: $pb.findvotewinner
    .timer 1 4 msg $pb.channel Server address and password will be send to you in a private message.
    set %m 1
    while (%m <= $pb.players) {
      .timer 1 $calc(%m * 5) .msg $hget(pb.users,%m) $replace($replace($pb.serverline,&team,$iif($hget(pb.users,%m $$+ .team) == 1,4RED,12BLUE)),&captain,$iif($hget(pb.users,%m $$+ .captain) == 1,YES,NO))
      inc %m
    }
    .timer$done 1 $pb.time pb.done
    set %pb.gameover.users $null
    set %pb.gameover $calc( $pb.players / 2 )
  }
}

alias -l pb.usermsg {
  set %number $hget(pb,pickup)
  if (%number > 0) {
    msg $pb.channel $replace($pb.playing,&time,$asctime($calc(%number - $ctime),nn:ss))
  }
  elseif ($calc($pb.players - $pb.getnumplayers) == $pb.players) {
    msg $pb.channel $pb.style.players $$+ Nobody signed up for a game. Signup with !add [red/blue]
  }
  else {
    msg $pb.channel $pb.style.players $$+ Signed up players: [ $$+ $pb.getnumplayers $$+ / $$+ $pb.players $$+ ]: $pb.getplayers - Needed: $calc($pb.players - $pb.getnumplayers)
  }
}

/*
Ban functions
*/

alias -l pb.checkban {
  ;$1 = mask
  set %chans $chan(0)
  set %p 0
  while (%p <= %chans) {
    set %chan $chan(%p)
    set %i $ialchan($1,%chan,0)
    while (%i > 0) {
      set %x $ialchan($1,%chan,%i).nick
      mode %chan +b $1
      kick %chan %x $$2-
      dec %i
    }
    inc %p
  }
}

alias pb.checklamers {
  ; get bans from hashtable and check them with checkban function
  unset %pb.ban
  set %f 1000
  set %k 0
  while (%k <= %f) {
    set %pb.ban $hget(pb.bans,%k $$+ .host)
    set %pb.banr $hget(pb.bans,%k $$+ .reason)
    if (%pb.ban != $null) {
      pb.checkban %pb.ban %pb.banr
    }
    inc %k
  }
}

alias -l pb.addban {
  ; $1 nick/host, $2 time, $3- reason
  unset %pb.ban
  set %f 1000
  set %k 0
  while (%k <= %f) {
    set %pb.ban $hget(pb.bans,%k $$+ .host)
    if (%pb.ban == $null) {
      if ($chr(42) isin $1) {
        hadd pb.bans %k $$+ .nick %k
        hadd pb.bans %k $$+ .host $1
        hadd pb.bans %k $$+ .time $calc( $ctime + $pb.maketime($2) )
        hadd pb.bans %k $$+ .reason $3-
        pb.checklamers
        break
      }
      else {
        if ($1 !isop $pb.channel) {
          hadd pb.bans %k $$+ .nick $1
          hadd pb.bans %k $$+ .host $address($1,0)
          hadd pb.bans %k $$+ .time $calc( $ctime + $pb.maketime($2) )
          hadd pb.bans %k $$+ .reason $3-
          pb.checklamers
          break
        }
      }
    }
    inc %k
  }
}

alias -l pb.delban {
  ; $1 = nick/id
  set %f 1000
  set %k 0
  while (%k <= %f) {
    set %pb.ban $hget(pb.bans,%k $$+ .nick)
    if (%pb.ban != $null) {
      if (%pb.ban == $1) {
        set %pb.banh $hget(pb.bans,%k $$+ .host)
        mode $pb.channel -b %pb.banh
        hdel pb.bans %k $$+ .nick
        hdel pb.bans %k $$+ .host
        hdel pb.bans %k $$+ .time
        hdel pb.bans %k $$+ .reason
        msg $pb.channel [Removed] ban for %pb.ban
      }
    }
    inc %k
  }
}

alias -l pb.findban {
  ; $1 = search key, $2 is number (optioneel)
  unset %pb.found*
  set %pb.item $2
  if ($2 == $null) { set %pb.item 1 }
  set %pb.found1 $hfind(pb.bans,$1,0,n).data
  set %pb.found2 $hfind(pb.bans,$1,0,w).data
  set %pb.found3 $hfind(pb.bans,$1,0,W).data
  set %b 0
  if (%pb.found1 > 0) {
    set %item $hfind(pb.bans,$1,%pb.item,n).data
    set %item2 $mid(%item,1,$calc( $pos(%item,$chr(46),1) - 1 ))
    return ( $$+ %pb.item $$+ / $$+ %pb.found1 $$+ ) [nick] $hget(pb.bans,%item2 $$+ .nick) [host] $hget(pb.bans,%item2 $$+ .host) [reason] $hget(pb.bans,%item2 $$+ .reason) [Unban] $duration($calc($hget(pb.bans,%item2 $$+ .time) - $ctime),3)
  }
  if (%pb.found2 > 0) {
    set %item $hfind(pb.bans,$1,%pb.item,w).data
    set %item2 $mid(%item,1,$calc( $pos(%item,$chr(46),1) - 1 ))
    return ( $$+ %pb.item $$+ / $$+ %pb.found2 $$+ ) [nick] $hget(pb.bans,%item2 $$+ .nick) [host] $hget(pb.bans,%item2 $$+ .host) [reason] $hget(pb.bans,%item2 $$+ .reason) [Unban] $duration($calc($hget(pb.bans,%item2 $$+ .time) - $ctime),3)
  }
  if (%pb.found3 > 0) {
    set %item $hfind(pb.bans,$1,%pb.item,W).data
    set %item2 $mid(%item,1,$calc( $pos(%item,$chr(46),1) - 1 ))
    return ( $$+ %pb.item $$+ / $$+ %pb.found3 $$+ ) [nick] $hget(pb.bans,%item2 $$+ .nick) [host] $hget(pb.bans,%item2 $$+ .host) [reason] $hget(pb.bans,%item2 $$+ .reason) [Unban] $duration($calc($hget(pb.bans,%item2 $$+ .time) - $ctime),3)
  }
}

alias pb.checkunban {
  unset %pb.ban
  set %f 1000
  set %k 0
  while (%k <= %f) {
    set %pb.ban $hget(pb.bans,%k $$+ .host)
    set %pb.bant $hget(pb.bans,%k $$+ .time)
    if (%pb.ban != $null) {
      if ($calc( $ctime - %pb.bant ) > 0 ) {
        mode $pb.channel -b %pb.ban
        hdel pb.bans %k $$+ .nick
        hdel pb.bans %k $$+ .host
        hdel pb.bans %k $$+ .time
        hdel pb.bans %k $$+ .reason
      }
    }
    inc %k
  }
}

alias pb.maketime {
  ;make time
  ; s=seconds, m=minutes, h=hours, d=days, y=years
  ; $1 = line
  ; example: 10d2h5s
  set %pb.ma $len($1)
  set %pb.tm 0
  set %pb.cn 1
  set %pb.num $null
  set %pb.ca $null
  while ($true) {
    if (%pb.cn > %pb.ma) {
      break
    }
    set %pb.case $mid($1,%pb.cn,1)
    if (%pb.case isnum) {
      set %pb.num %pb.num $$+ %pb.case
    }
    else {
      if (%pb.num != $null) {
        if (%pb.case == y) {
          set %pb.tm $calc( %pb.tm + ( 30758400 * %pb.num ) )
        }
        if (%pb.case == d) {
          set %pb.tm $calc( %pb.tm + ( 86400 * %pb.num ) )
        }
        if (%pb.case == h) {
          set %pb.tm $calc( %pb.tm + ( 3600 * %pb.num ) )
        }
        if (%pb.case == m) {
          set %pb.tm $calc( %pb.tm + ( 60 * %pb.num ) )
        }
        if (%pb.case == s) {
          set %pb.tm $calc( %pb.tm + ( %pb.num ) )
        }
      } 
      set %pb.num $null
    }
    unset %pb.case
    inc %pb.cn
  }
  return %pb.tm
}

; -- PICKUP EVENTS -- 

on *:TEXT:*:#: {
  ;yeah baby
  if ($chan == $pb.channel) {
    if (%pb.active == $true) {
      if ($1 == !add) {
        pb.adduser $nick $address($nick,0) $2
      }
      if ($1 == !addme) {
        pb.adduser $nick $address($nick,0) $2
      }
      if ($1 == !remove || $1 == !leave || $1 == !removeme && $pb.isrunning == $false) {
        pb.deluser $nick
      }
      if ($1 == !status) {
        pb.usermsg
      }
      if ($1 == !report || $1 == !reporter) {
        msg $pb.channel $pb.reporter
      }
      if ($1 == !vote && $pb.isrunning == $false) {
        if ($2 == $null) {
          msg $pb.getchannel Allowed maps: $pb.getmaplist
        }
        else {
          pb.addvote $2 $nick
        }
      }
      if ($1 == !team && $pb.isrunning == $false && $pb.allowteams == $true) {
        if ($pb.isuser($nick) == $false) { halt }
        set %n 0
        set %m 1
        set %player 1
        while (%m <= $pb.players) {
          set %player $hget(pb.users,%m)
          if (%player == $nick) {
            break
          }
          inc %m
        }
        if (%m > $pb.players) {
          ;not here
          halt
        }
        ;check for parameters
        if ($2 == red) {
          hadd pb.users %m $$+ .team 1
          notice $nick You are now on 4RED
        }
        elseif ($2 == blue) {
          hadd pb.users %m $$+ .team 2
          notice $nick You are now on 12BLUE
        }
        else {
          set %pb.team $hget(pb.users,%m $$+ .team)
          if (%pb.team == 0) {
            set %pb.team2 random
          }
          elseif (%pb.team == 1) {
            set %pb.team2 red
          }
          elseif (%pb.team == 2) {
            set %pb.team2 blue
          }
          msg $pb.channel $nick $$+ : You are currently on the %pb.team2 team

          unset %pb.team
        }

      }
      if ($1 == !promote && $pb.isrunning == $false) {
        set %number $hget(pb,pickup)
        if (%number > 0) {
        }
        else {
          msg $pb.channel $replace($pb.style.promote,&players,$calc($pb.players - $pb.getnumplayers))
        }
      }
      if ($1 == !gameover) {
        if ($pb.isuser($nick) == $true && $pb.isrunning == $true) {
          if ($findtok(%pb.gameover.users,$nick,1,32) == $null) {
            dec %pb.gameover
            set %pb.gameover.users %pb.gameover.users $nick
            if (%pb.gameover <= 0) {
              pb.done
            }
            else {
              msg $pb.channel Thanks for playing $nick - need %pb.gameover more players to say !gameover
            }
          }
        }
      }
    }
  }
  if ($chan == $pb.channel || $chan == $pb.adminchan) {
    if ($nick isop $chan) {
      if ($1 == !reset) {
        pb.done
      }
      if ($1 == !save) {
        pb.save
      }
      if ($1 == !stats) {
        msg $chan [Stats] $hget(pb,number) pickups have been played!
      }
      if ($1 == !addmap) {
        pb.addmap $2
        pb.save
      }
      if ($1 == !delmap) {
        pb.delmap $2
        pb.save
      }
      if ($1 == !start) {
        set %pb.active $true
        msg $chan Bot activated
      }
      if ($1 == !stop) {
        set %pb.active $false
        msg $chan Bot deactivated
      }
      if ($1 == !kill) {
        pb.save
        quit
      }
      if ($1 == !showlog) {
        ;this sux, the layout. Just make a way to process it. no time atm for that:p
        if ($2 != $null) {
          hmake pb.log
          hload pb.log pickuplog. $$+ $2 $$+ .txt
          msg $chan Log of pickup number $hget(pb.log,number)
          set %n 1
          while (%n <= $pb.players) {
            .timer 1 $calc(%n + ( %n * 2 )) msg $chan Player %n was $hget(pb.log,p $$+ %n) ( $$+ $hget(pb.log,ph $$+ %n) $$+ ) on team $iif($hget(pb.log,pt $$+ %n) != 0 && $hget(pb.log,pt $$+ %n) == 1,RED,BLUE) - $iif($hget(pb.log,pc $$+ %n) == 1,TEAMCAPTAIN,$null)
            inc %n
          }
          hfree pb.log
        }
      }
      if ($1 == !host) {
        if ($2 != $null) {
          set %host $hget(pb.hist,$2)
          if (%host == $null) {
            msg $chan The player $2 has not been found
          }
          else {
            msg $chan Last host of $2 $$+ : %host
          }
          unset %host
        }
      }
      if ($1 == !kb || $1 == !b || $1 == !ban || $1 == !kick || $1 == !k ) {
        ;kickban feature
        ;!kb nickname duration why
        if ($2 != $null && $3 != $null && $4 != $null) {
          pb.addban $2 $3 $4-
          notice $nick Your target ( $$+ $2 $$+ ) has been banned!
          pb.save
        }
      }
      if ($1 == !fban || $1 == !findban) {
        if ($2 != $null) {
          set %banfound $pb.findban($2,$3)
          msg $chan $iif(%banfound == $null,[Notice] No ban was found,[Notice] Found ban: %banfound)
          unset %banfound
        }
      }
      if ($1 == !delban || $1 == !remban) {
        if ($2 != $null) {
          pb.delban $2
          pb.save
        }
      }
    }
  }
  return 1
  :error
  echo -s PICKUPBOT ERROR: $error
  hfree pb.log
  reseterror
}


; -- OTHER -- 

on *:START: {
  echo -s Pickupbot starting...
  if ($pb.init == 1) {
    echo -s Pickupbot started
    set %pb.active $true
    .timer 0 10 pb.checkunban
  }
  else {
    echo -s Pickupbot startup FAILED
  }
}

on *:NICK: {
  ;nickchange
  if ($pb.isuser($nick) == $true) {
    hadd pb.users $pb.getuser($nick) $newnick
  }
}

on *:QUIT: {
  if ($pb.isuser($nick) == $true) {
    pb.deluser $nick
  }
  if ($nick == $me) {
    server $pb.getserver
  }
}

on *:PART:#: {
  if ($pb.isuser($nick) == $true && $chan == $pb.channel) {
    pb.deluser $nick
  }
}

on *:JOIN:#: {
  if ($chan == $pb.channel && $pb.channel.autovoice == $true) {
    mode # +v $nick
  }
  pb.checklamers
  if ($nick == $me) {
    who $chan
    msg # $pb.credits
    ;update IAL
    ;now check for lamers
    .timer 1 10 pb.checklamers
  }
}
on *:KICK:#: {
  if ($pb.isuser($knick) == $true && $chan == $pb.channel) {
    pb.deluser $knick
  }
  if ($chan == $pb.channel && $knick == $me) {
    join $chan
  }
}

on *:LOAD: {
  echo -s Pickupbot starting...
  if ($pb.init == 1) {
    echo -s Pickupbot started
    set %pb.active $true
    .timer 0 10 pb.checkunban
  }
  else {
    echo -s Pickupbot startup FAILED
  }
}

on *:CONNECT: {
  pb.dojoin
}



alias pb.dojoin {
  if ($server != $null) {
    pb.auth
    join $pb.getchannel
    if ($pb.useadminchan == $true) {
      join $pb.adminchan
    }
    mode $me +ix
  }
}

ctcp *:*:*:{
  if (%pb.ctcp == 1) { 
    halt 
  }
  else {
    if ($istok(version userinfo clientinfo script,$1,32)) { 
      set -u60 %pb.ctcp 1
      .ctcpreply $nick VERSION 07[4- 14P07ickupbot 14v07ersion $pb.version 4- 14b07y 14M07oeh14M07an 4- 07www.moehman.nl 4-07]
    }
  }
}
