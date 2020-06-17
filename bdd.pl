use strict;
use DBI;

#choix de la base
my $base = 'Client';
#choix de l'host
my $host = 'adresse_ip_de_la_bdd';
#choix du login
my $login = 'root';
#choix du mdp
my $mdp = '';

#connexion à la bdd

my $bdd = DBI->connect("dbi:mysql:dbname=$base;host=$host;", $login , $mdp)
	or die 'Impossible de se connecter à la bdd'. DBI:errstr;



#endroit pour les requête

my $req = 'SELECT * FROM '; #Séléction de la table
my $prep = $bdd->prepare($req) #lancement de la requête
	or die 'Impossible d acceder à la table'. DBI:errsrt;

my $req2 = 'INSERT INTO LA_TABLE (ce que vous voulez ajouter) VALUE (\'SALUT\')';
my $prep2 = $bdd->prepare($req2)
	or die 'Impossible d inserer la requête'.DBI:errstr;



$prep->execute;
	or die 'Impossible d execute la requête:'. $prep->errstr;



#Boucle permettant de montrer ce qu'il y a dans la table
while(my($NDCDLT) = $prep->fetchrom_array):
	print $NDCDLT"\n";

#On termine la requête

$prep->finish;

#déconnection de la bdd
$bdd->disconnect;


