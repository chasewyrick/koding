{argv} = require 'optimist'
KONFIG = require('koding-config-manager').load("main.#{argv.c}")
redis  = require "redis"
REDIS_KEY = "social:disposable-email-addresses"
DOMAINS = [
  "0-mail.com",
  "0815.ru",
  "0815.su",
  "0clickemail.com",
  "0wnd.net",
  "0wnd.org",
  "10minutemail.com",
  "10minutemail.de",
  "123-m.com",
  "126.com",
  "12minutemail.com",
  "139.com",
  "163.com",
  "1ce.us",
  "1chuan.com",
  "1pad.de",
  "1zhuan.com",
  "20minutemail.com",
  "21cn.com",
  "24hourmail.com",
  "2prong.com",
  "30minutemail.com",
  "33mail.com",
  "3d-painting.com",
  "4warding.com",
  "4warding.net",
  "4warding.org",
  "60minutemail.com",
  "60minutemail.com ",
  "675hosting.com",
  "675hosting.net",
  "675hosting.org",
  "6paq.com",
  "6url.com",
  "75hosting.com",
  "75hosting.net",
  "75hosting.org",
  "7days-printing.com",
  "7tags.com",
  "99experts.com",
  "9ox.net",
  "SendSpamHere.com",
  "SpamHereLots.com",
  "SpamHerePlease.com",
  "TempEMail.net",
  "a-bc.net",
  "a45.in",
  "afrobacon.com",
  "ag.us.to",
  "agedmail.com",
  "ajaxapp.net",
  "alivance.com",
  "amilegit.com",
  "amiri.net",
  "amiriindustries.com",
  "anappthat.com",
  "ano-mail.net",
  "anonbox.net",
  "anonymail.dk",
  "anonymbox.com",
  "antichef.com",
  "antichef.net",
  "antispam.de",
  "armyspy.com",
  "azmeil.tk",
  "baxomale.ht.cx",
  "beddly.com",
  "beefmilk.com",
  "big1.us",
  "bigprofessor.so",
  "bigstring.com",
  "binkmail.com",
  "bio-muesli.net",
  "blogmyway.org",
  "bobmail.info",
  "bodhi.lawlita.com",
  "bofthew.com",
  "bootybay.de",
  "boun.cr",
  "bouncr.com",
  "boxformail.in",
  "brefmail.com",
  "brennendesreich.de",
  "broadbandninja.com",
  "bsnow.net",
  "bu.mintemail.com",
  "buffemail.com",
  "bugmenot.com",
  "bumpymail.com",
  "bund.us",
  "bundes-li.ga",
  "burnthespam.info",
  "buyusedlibrarybooks.org",
  "c2.hu",
  "cachedot.net",
  "casualdx.com",
  "cellurl.com",
  "centermail.com",
  "centermail.net",
  "chammy.info",
  "cheatmail.de",
  "chogmail.com",
  "choicemail1.com",
  "chong-mail.com",
  "chong-mail.net",
  "chong-mail.org",
  "clixser.com",
  "cmail.com",
  "cmail.net",
  "cmail.org",
  "consumerriot.com",
  "cool.fr.nf",
  "correo.blogos.net",
  "cosmorph.com",
  "courriel.fr.nf",
  "courrieltemporaire.com",
  "crapmail.org",
  "crazymailing.com",
  "cubiclink.com",
  "curryworld.de",
  "cust.in",
  "cuvox.de",
  "dacoolest.com",
  "dandikmail.com",
  "dayrep.com",
  "dbunker.com",
  "dcemail.com",
  "deadaddress.com",
  "deadchildren.org",
  "deadspam.com",
  "deagot.com",
  "dealja.com",
  "despam.it",
  "despammed.com",
  "devnullmail.com",
  "dfgh.net",
  "dharmatel.net",
  "digitalsanctuary.com",
  "dingbone.com",
  "discard.email",
  "discardmail.com",
  "discardmail.de",
  "disposableaddress.com",
  "disposableemailaddresses.com",
  "disposableinbox.com",
  "dispose.it",
  "disposeamail.com",
  "disposemail.com",
  "dispostable.com",
  "dm.w3internet.co.ukexample.com",
  "dodgeit.com",
  "dodgit.com",
  "dodgit.org",
  "doiea.com",
  "domozmail.com",
  "donemail.ru",
  "dontreg.com",
  "dontsendmespam.de",
  "dotmsg.com",
  "drdrb.com",
  "drdrb.net",
  "dudmail.com",
  "dump-email.info",
  "dumpandjunk.com",
  "dumpmail.de",
  "dumpyemail.com",
  "duskmail.com",
  "e-mail.com",
  "e-mail.org",
  "e4ward.com",
  "easytrashmail.com",
  "einrot.com",
  "einrot.de",
  "email60.com",
  "emaildienst.de",
  "emailgo.de",
  "emailias.com",
  "emailigo.de",
  "emailinfive.com",
  "emailisvalid.com",
  "emaillime.com",
  "emailmiser.com",
  "emailsensei.com",
  "emailtemporar.ro",
  "emailtemporario.com.br",
  "emailthe.net",
  "emailtmp.com",
  "emailto.de",
  "emailwarden.com",
  "emailx.at.hm",
  "emailxfer.com",
  "emeil.in",
  "emeil.ir",
  "emz.net",
  "enterto.com",
  "ephemail.net",
  "etranquil.com",
  "etranquil.net",
  "etranquil.org",
  "evopo.com",
  "example.com",
  "explodemail.com",
  "explodemail.com ",
  "eyepaste.com",
  "fakeinbox.com",
  "fakeinformation.com",
  "fakemail.fr",
  "fakemailgenerator.com",
  "fakemailz.com",
  "fammix.com",
  "fansworldwide.de",
  "fantasymail.de",
  "fastacura.com",
  "fastchevy.com",
  "fastchrysler.com",
  "fastkawasaki.com",
  "fastmazda.com",
  "fastmitsubishi.com",
  "fastnissan.com",
  "fastsubaru.com",
  "fastsuzuki.com",
  "fasttoyota.com",
  "fastyamaha.com",
  "fatflap.com",
  "fdfdsfds.com",
  "fightallspam.com",
  "filzmail.com",
  "fixmail.tk",
  "fizmail.com",
  "fleckens.hu",
  "flyspam.com",
  "footard.com",
  "forgetmail.com",
  "fornow.eu",
  "fr33mail.info",
  "frapmail.com",
  "freemail.ms",
  "freundin.ru",
  "friendlymail.co.uk",
  "front14.org",
  "fuckingduh.com",
  "fudgerub.com",
  "fux0ringduh.com",
  "garliclife.com",
  "gawab.com",
  "gelitik.in",
  "get1mail.com",
  "get2mail.fr",
  "getairmail.com",
  "getmails.eu",
  "getonemail.com",
  "getonemail.net",
  "ghosttexter.de",
  "girlsundertheinfluence.com",
  "gishpuppy.com",
  "goemailgo.com",
  "gorillaswithdirtyarmpits.com",
  "gotmail.com",
  "gotmail.net",
  "gotmail.org",
  "gotti.otherinbox.com",
  "gowikibooks.com",
  "gowikicampus.com",
  "gowikicars.com",
  "gowikifilms.com",
  "gowikigames.com",
  "gowikimusic.com",
  "gowikinetwork.com",
  "gowikitravel.com",
  "gowikitv.com",
  "grandmasmail.com",
  "great-host.in",
  "greensloth.com",
  "grr.la",
  "gsrv.co.uk",
  "guerillamail.biz",
  "guerillamail.com",
  "guerillamail.net",
  "guerillamail.org",
  "guerrillamail.biz",
  "guerrillamail.com",
  "guerrillamail.de",
  "guerrillamail.net",
  "guerrillamail.org",
  "guerrillamailblock.com",
  "gustr.com",
  "h.mintemail.com",
  "h8s.org",
  "hacccc.com",
  "haltospam.com",
  "hartbot.de",
  "hatespam.org",
  "herp.in",
  "hidemail.de",
  "hidzz.com",
  "hmamail.com",
  "hochsitze.com",
  "hotpop.com",
  "hulapla.de",
  "hushmail.com",
  "ieatspam.eu",
  "ieatspam.info",
  "ieh-mail.de",
  "ihateyoualot.info",
  "iheartspam.org",
  "imails.info",
  "imgof.com",
  "imstations.com",
  "inbax.tk",
  "inbox.si",
  "inboxalias.com",
  "inboxclean.com",
  "inboxclean.org",
  "incognitomail.com",
  "incognitomail.net",
  "incognitomail.org",
  "insorg-mail.info",
  "instant-mail.de",
  "instantemailaddress.com",
  "ipoo.org",
  "irish2me.com",
  "iroid.com",
  "iwi.net",
  "jetable.com",
  "jetable.fr.nf",
  "jetable.net",
  "jetable.org",
  "jnxjn.com",
  "jourrapide.com",
  "jsrsolutions.com",
  "junk1e.com",
  "kasmail.com",
  "kaspop.com",
  "keepmymail.com",
  "killmail.com",
  "killmail.net",
  "kir.ch.tc",
  "klassmaster.com",
  "klassmaster.net",
  "klzlk.com",
  "koszmail.pl",
  "kulturbetrieb.info",
  "kurzepost.de",
  "l33r.eu",
  "lackmail.net",
  "lavabit.com",
  "letthemeatspam.com",
  "lhsdv.com",
  "lifebyfood.com",
  "link2mail.net",
  "litedrop.com",
  "loadby.us",
  "lol.ovpn.to",
  "lookugly.com",
  "lopl.co.cc",
  "lortemail.dk",
  "lovemeleaveme.com",
  "lr7.us",
  "lr78.com",
  "lroid.com",
  "luv2.us",
  "m4ilweb.info",
  "maboard.com",
  "mail-filter.com",
  "mail-temporaire.fr",
  "mail.by",
  "mail.mezimages.net",
  "mail114.net",
  "mail2rss.org",
  "mail333.com",
  "mail4trash.com",
  "mailbidon.com",
  "mailblocks.com",
  "mailbucket.org",
  "mailcatch.com",
  "maildrop.cc",
  "maileater.com",
  "mailexpire.com",
  "mailfa.tk",
  "mailfreeonline.com",
  "mailguard.me",
  "mailimate.com",
  "mailin8r.com",
  "mailinater.com",
  "mailinator.com",
  "mailinator.net",
  "mailinator.org",
  "mailinator.us",
  "mailinator2.com",
  "mailincubator.com",
  "mailismagic.com",
  "mailmate.com",
  "mailme.ir",
  "mailme.lv",
  "mailme24.com",
  "mailmetrash.com",
  "mailmoat.com",
  "mailnator.com",
  "mailnesia.com",
  "mailnull.com",
  "mailquack.com",
  "mailsac.com",
  "mailscrap.com",
  "mailseal.de",
  "mailshell.com",
  "mailsiphon.com",
  "mailslapping.com",
  "mailslite.com",
  "mailtemp.info",
  "mailtothis.com",
  "mailzilla.com",
  "mailzilla.org",
  "makemetheking.com",
  "manifestgenerator.com",
  "manybrain.com",
  "mbx.cc",
  "mciek.com",
  "mega.zik.dj",
  "meinspamschutz.de",
  "meltmail.com",
  "messagebeamer.de",
  "mezimages.net",
  "mierdamail.com",
  "migumail.com",
  "mintemail.com",
  "mjukglass.nu",
  "mobi.web.id",
  "mobileninja.co.uk",
  "moburl.com",
  "moncourrier.fr.nf",
  "monemail.fr.nf",
  "monmail.fr.nf",
  "monumentmail.com",
  "ms9.mailslite.com",
  "msa.minsmail.com",
  "mt2009.com",
  "mt2014.com",
  "mx0.wwwnew.eu",
  "mycleaninbox.net",
  "myemailboxy.com",
  "mymail-in.net",
  "mynetstore.de",
  "mypacks.net",
  "mypartyclip.de",
  "myphantomemail.com",
  "myspaceinc.com",
  "myspaceinc.net",
  "myspaceinc.org",
  "myspacepimpedup.com",
  "myspamless.com",
  "mytempemail.com",
  "mytrashmail.com",
  "neomailbox.com",
  "nepwk.com",
  "nervmich.net",
  "nervtmich.net",
  "netmails.com",
  "netmails.net",
  "netzidiot.de",
  "neverbox.com",
  "nice-4u.com",
  "no-spam.ws",
  "nobulk.com",
  "noclickemail.com",
  "nogmailspam.info",
  "nomail.xl.cx",
  "nomail2me.com",
  "nomorespamemails.com",
  "nonspam.eu",
  "nonspammer.de",
  "noref.in",
  "nospam.wins.com.br",
  "nospam.ze.tc",
  "nospam4.us",
  "nospamfor.us",
  "nospamthanks.info",
  "notmailinator.com",
  "notsharingmy.info",
  "nowhere.org",
  "nowmymail.com",
  "ntlhelp.net",
  "nurfuerspam.de",
  "nus.edu.sg",
  "nwldx.com",
  "objectmail.com",
  "obobbo.com",
  "odaymail.com",
  "oneoffemail.com",
  "oneoffmail.com",
  "onewaymail.com",
  "online.ms",
  "oopi.org",
  "opayq.com",
  "ordinaryamerican.net",
  "otherinbox.com",
  "ourklips.com",
  "outlawspam.com",
  "ovpn.to",
  "owlpic.com",
  "pancakemail.com",
  "paplease.com",
  "pcusers.otherinbox.com",
  "pepbot.com",
  "pfui.ru",
  "pimpedupmyspace.com",
  "pjjkp.com",
  "plexolan.de",
  "poczta.onet.pl",
  "politikerclub.de",
  "poofy.org",
  "pookmail.com",
  "postacin.com",
  "privacy.net",
  "privy-mail.com",
  "privymail.de",
  "proxymail.eu",
  "prtnx.com",
  "prtz.eu",
  "punkass.com",
  "putthisinyourspamdatabase.com",
  "pwrby.com",
  "qq.com",
  "quickinbox.com",
  "rcpt.at",
  "reallymymail.com",
  "receiveee.chickenkiller.com",
  "receiveee.com",
  "recode.me",
  "recursor.net",
  "reconmail.com",
  "recursor.net",
  "recyclemail.dk",
  "regbypass.com",
  "regbypass.comsafe-mail.net",
  "rejectmail.com",
  "rhyta.com",
  "rk9.chickenkiller.com",
  "rklips.com",
  "rmqkr.net",
  "royal.net",
  "rppkn.com",
  "rtrtr.com",
  "ruffrey.com",
  "s0ny.net",
  "safe-mail.net",
  "safersignup.de",
  "safetymail.info",
  "safetypost.de",
  "sandelf.de",
  "saynotospams.com",
  "scatmail.com",
  "schafmail.de",
  "selfdestructingmail.com",
  "selfdestructingmail.org",
  "SendSpamHere.com",
  "sharklasers.com",
  "shieldedmail.com",
  "shiftmail.com",
  "shitmail.me",
  "shitmail.org",
  "shitware.nl",
  "shortmail.net",
  "sibmail.com",
  "sinnlos-mail.de",
  "siteposter.net",
  "skeefmail.com",
  "slaskpost.se",
  "slave-auctions.net",
  "slopsbox.com",
  "slushmail.com",
  "smashmail.de",
  "smellfear.com",
  "snakemail.com",
  "sneakemail.com",
  "snkmail.com",
  "sofimail.com",
  "sofort-mail.de",
  "sogetthis.com",
  "sohu.com",
  "soisz.com",
  "soodomail.com",
  "soodonims.com",
  "spam-be-gone.com",
  "spam.la",
  "spam.su",
  "spam4.me",
  "spamavert.com",
  "spambob.com",
  "spambob.net",
  "spambob.org",
  "spambog.com",
  "spambog.de",
  "spambog.net",
  "spambog.ru",
  "spambox.info",
  "spambox.irishspringrealty.com",
  "spambox.us",
  "spamcannon.com",
  "spamcannon.net",
  "spamcero.com",
  "spamcon.org",
  "spamcorptastic.com",
  "spamcowboy.com",
  "spamcowboy.net",
  "spamcowboy.org",
  "spamday.com",
  "spamdecoy.net",
  "spamex.com",
  "spamfree.eu",
  "spamfree24.com",
  "spamfree24.de",
  "spamfree24.eu",
  "spamfree24.info",
  "spamfree24.net",
  "spamfree24.org",
  "spamgoes.in",
  "spamgourmet.com",
  "spamgourmet.net",
  "spamgourmet.org",
  "SpamHereLots.com",
  "SpamHerePlease.com",
  "spamhole.com",
  "spamify.com",
  "spaminator.de",
  "spamkill.info",
  "spaml.com",
  "spaml.de",
  "spammotel.com",
  "spamobox.com",
  "spamoff.de",
  "spamsalad.in",
  "spamslicer.com",
  "spamspot.com",
  "spamstack.net",
  "spamthis.co.uk",
  "spamthisplease.com",
  "spamtrail.com",
  "spamtroll.net",
  "speed.1s.fr",
  "spoofmail.de",
  "squizzy.de",
  "startkeys.com",
  "stinkefinger.net",
  "stop-my-spam.com",
  "stuffmail.de",
  "supergreatmail.com",
  "supermailer.jp",
  "superrito.com",
  "superstachel.de",
  "suremail.info",
  "sweetxxx.de",
  "tagyourself.com",
  "talkinator.com",
  "tapchicuoihoi.com",
  "teewars.org",
  "teleworm.com",
  "teleworm.us",
  "temp.emeraldwebmail.com",
  "tempalias.com",
  "tempe-mail.com",
  "tempemail.biz",
  "tempemail.co.za",
  "tempemail.com",
  "TempEMail.net",
  "tempinbox.co.uk",
  "tempinbox.com",
  "tempmail.it",
  "tempmail2.com",
  "tempmaildemo.com",
  "tempomail.fr",
  "temporarily.de",
  "temporarioemail.com.br",
  "temporaryemail.net",
  "temporaryemail.us",
  "temporaryforwarding.com",
  "temporaryinbox.com",
  "tempthe.net",
  "tempymail.com",
  "thanksnospam.info",
  "thankyou2010.com",
  "thecloudindex.com",
  "thisisnotmyrealemail.com",
  "throwawayemailaddress.com",
  "throwawaymail.com",
  "tilien.com",
  "tittbit.in",
  "tmailinator.com",
  "toiea.com",
  "tradermail.info",
  "trash-amil.com",
  "trash-mail.at",
  "trash-mail.com",
  "trash-mail.de",
  "trash2009.com",
  "trash2010.com",
  "trash2011.com",
  "trashdevil.com",
  "trashdevil.de",
  "trashemail.de",
  "trashmail.at",
  "trashmail.com",
  "trashmail.de",
  "trashmail.me",
  "trashmail.net",
  "trashmail.org",
  "trashmail.ws",
  "trashmailer.com",
  "trashymail.com",
  "trashymail.net",
  "trayna.com",
  "trbvm.com",
  "trillianpro.com",
  "tryalert.com",
  "turual.com",
  "twinmail.de",
  "tyldd.com",
  "uggsrock.com",
  "umail.net",
  "unmail.ru",
  "upliftnow.com",
  "uplipht.com",
  "uroid.com",
  "venompen.com",
  "veryrealemail.com",
  "vidchart.com",
  "viditag.com",
  "viewcastmedia.com",
  "viewcastmedia.net",
  "viewcastmedia.org",
  "vubby.com",
  "walala.org",
  "walkmail.net",
  "webemail.me",
  "webm4il.info",
  "webuser.in",
  "weg-werf-email.de",
  "wegwerf-email-addressen.de",
  "wegwerf-emails.de",
  "wegwerfadresse.de",
  "wegwerfemail.de",
  "wegwerfmail.de",
  "wegwerfmail.info",
  "wegwerfmail.net",
  "wegwerfmail.org",
  "wetrainbayarea.com",
  "wetrainbayarea.org",
  "wh4f.org",
  "whatiaas.com",
  "whatpaas.com",
  "whatsaas.com",
  "whopy.com",
  "whyspam.me",
  "wilemail.com",
  "willselfdestruct.com",
  "winemaven.info",
  "wronghead.com",
  "wuzup.net",
  "wuzupmail.net",
  "wwwnew.eu",
  "xagloo.com",
  "xemaps.com",
  "xents.com",
  "xmaily.com",
  "xoxox.cc",
  "xoxy.net",
  "xyzfree.net",
  "yahoo.com.ph",
  "yahoo.com.vn",
  "yapped.net",
  "yeah.net",
  "yep.it",
  "yogamaven.com",
  "yopmail.com",
  "yopmail.fr",
  "yopmail.net",
  "ypmail.webarnak.fr.eu.org",
  "yuurok.com",
  "za.com",
  "zehnminutenmail.de",
  "zetmail.com",
  "zippymail.info",
  "zoaxe.com",
  "zoemail.com",
  "zoemail.net",
  "zoemail.org",
  "zomg.info"
]

endsWith = (str, suffix) ->
  str.indexOf(suffix, str.length - suffix.length) != -1

redisClient = null

check = (email)->
  for domain in DOMAINS
    return no  if endsWith email, "@#{domain}"
  return yes

syncWithRedis = (callback)->

  unless redisClient
    redisClient = redis.createClient(
      KONFIG.monitoringRedis.split(":")[1]
      KONFIG.monitoringRedis.split(":")[0]
      {}
    )

  redisClient.smembers REDIS_KEY, (err, domains)->

    console.warn err  if err?
    domains ?= []

    DOMAINS.push domain for domain in domains when domain not in DOMAINS

    callback null


module.exports = (email, callback = ->)->

  syncWithRedis -> callback check email

  return check email
