@echo off
:: podwójnie, bo Win7 wyrzuca błąd ...@echo (po wyedytowaniu Notatnikiem systemowym) i wszystko się sypie...
@echo off
echo.
echo v4 25/03/2022
echo.
echo Skrypt generujacy klucz S/MIME.
echo Szyfrowanie i podpisywanie e-maili.
:: [Certyfikat niekwalifikowany]
::
:: skrypt pod Windows 7 i wyżej
:: wykorzystuje program openssl.exe - testowano na wersji OpenSSL 1.1.1m i 1.1.1i (msys2)
:: do sprawdzenia poprawności użyto guiDumpASN-ng, xca.exe 2.4.0
:: ustawienia podobne do klucza "Free S/MIME Certificates" od firmy Actalis S.p.A.
:: https://www.actalis.it/documenti-it/caact-free-s-mime-certificates-policy.aspx  [strony 11-12]
::
:: program wykonuje się w katalogu w którym znajduje się .bat (pushd)
::
:: OpenSLL dla Windows możesz pobrać ze strony:
:: https://wiki.openssl.org/index.php/Binaries
::
:: najlepiej tworzyć klucz w ram-dysku (bezpieczeństwo, nie trzeba robić shred), skopiować foldery priv\ i z kluczem .p12 na pendriva; folder pub\ udostępnić
:: ImDisk Virtual Disk Driver  https://www.ltr-data.se/opencode.html/#ImDisk
:: RAM dysk - aktywuj na partycji "R:\" cmd:  imdisk -a -o rem,awe -m R: -s 256M & format R: /fs:exFAT /a:32K /q /y & pause
:: RAM dysk - odłącz cmd:  imdisk -D -m R:
::
::         Schemat klucza:
::           1. klucz Root CA (certyfikat dla klucza e-mail)
::              2. klucz e-mail (podpisywanie+szyfrowanie)
::
:: https://www.dalesandro.net/create-self-signed-smime-certificates/
:: https://www.globalsign.com/en/resources/white-paper-smime-compatibility.pdf
:: https://anomail.pl/generator-certyfikatow-smime/
:: https://security.stackexchange.com/a/219058
:: https://fam.tuwien.ac.at/~schamane/_/blog/2019-02-13_thunderbird_selfsigned.htm







set openssl="C:\Program Files\OpenSSL-Win64\bin\openssl.exe"

set o=Jarosław Kowalski
set email=a@edu.pl
set client_waznosc_dni=3650




set dlugosc_klucza=2048
set dlugosc_klucza_root=2048
set skrot=sha256
set cn=%o% (%date%)
set /A root_waznosc_dni=%client_waznosc_dni% + 1

set root_klucz=root.pem
set root_crt=root.crt
set root_klucz_inf=root.pem.txt
set root_crt_inf=root.crt.txt
set root_cnf=root.cnf

set klient_klucz=klient.pem
set klient_klucz_inf=klient.pem.txt
set klient_cnf=klient.cnf
set klient_csr=klient.csr
set klient_csr_inf=klient.csr.txt
set klient_crt=klient.crt
set klient_crt_inf=klient.crt.txt
set serial1=sn01.srl

set klucz_publiczny=klucz_publiczny.p7b
set klucz_publiczny_th1=01root.crt
set klucz_publiczny_th2=02user.crt
set fingerprint=fingerprint.txt
set checksum=checksum.sha256
set pass=tmp\pass.txt
set version=version.txt
set klucz_do_uzytku_wewnetrznego=KLUCZ_PRYWATNY
set klucz_do_uzytku_wewnetrznego_nazwa=TWOJ_KLUCZ.p12

:: Kreator na pewnym etapie wyrzuci błąd: Can't open C:\Program Files (x86)\Common Files\SSL/openssl.cnf for reading ...
:: kreator sam tworzy pliki konfiguracyjne i wg nich tworzy poprawny klucz S/MIME
:: dlatego na sztywno ustawiamy OPENSSL_CONF
set OPENSSL_CONF=priv\%klient_cnf%

pushd

echo.
%openssl% version

mkdir priv
mkdir pub
mkdir tmp

%openssl% version -a > priv\%version%

echo.
echo ....::::  Tworzenie klucza ROOT  ::::....
%openssl% genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:%dlugosc_klucza_root% -out priv\%root_klucz%
%openssl% pkey -in priv\%root_klucz% -text -noout > priv\%root_klucz_inf%

echo.
echo ....::::  Generowanie ustawien dla Root CA  ::::....
echo [ req ]> priv\%root_cnf%
echo default_md = %skrot%>> priv\%root_cnf%
echo distinguished_name = root_dn>> priv\%root_cnf%
echo x509_extensions = root_ext>> priv\%root_cnf%
echo req_extensions = root_ext>> priv\%root_cnf%
echo utf8 = yes>> priv\%root_cnf%
echo prompt = no>> priv\%root_cnf%
echo [ root_dn ]>> priv\%root_cnf%
echo commonName=%cn%>> priv\%root_cnf%
echo organizationName=%o%>> priv\%root_cnf%
echo countryName=PL>> priv\%root_cnf%
:: echo stateOrProvinceName=Mazowieckie>> priv\%root_cnf%
:: echo localityName=Warszawa>> priv\%root_cnf%
echo [ root_ext ]>> priv\%root_cnf%
echo basicConstraints = critical,CA:TRUE,pathlen:1>> priv\%root_cnf%
echo keyUsage = critical,keyCertSign,cRLSign>> priv\%root_cnf%
echo extendedKeyUsage = clientAuth,emailProtection>> priv\%root_cnf%
echo subjectKeyIdentifier = hash>> priv\%root_cnf%
echo authorityKeyIdentifier = keyid>> priv\%root_cnf%

echo.
echo ....::::  Generowanie certyfikatu Root CA i samopodpis  ::::....
%openssl% req -new -x509 -config priv\%root_cnf% -days %root_waznosc_dni% -key priv\%root_klucz% -out priv\%root_crt%
%openssl% x509 -in priv\%root_crt% -text -noout > priv\%root_crt_inf%

echo.
echo ....::::  Tworzenie klucza e-mail  ::::....
%openssl% genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:%dlugosc_klucza% -out priv\%klient_klucz%
%openssl% pkey -in priv\%klient_klucz% -text -noout > priv\%klient_klucz_inf%

echo.
echo ....::::  Generowanie ustawien dla certyfikatu e-mail  ::::....
echo [ req ]> priv\%klient_cnf%
echo default_md = %skrot%>> priv\%klient_cnf%
echo distinguished_name = client_dn>> priv\%klient_cnf%
echo utf8 = yes>> priv\%klient_cnf%
echo prompt = no>> priv\%klient_cnf%
echo [ client_dn ]>> priv\%klient_cnf%
echo commonName=%email%>> priv\%klient_cnf%
:: echo organizationName=%o%>> priv\%klient_cnf%
:: echo organizationalUnitName=Dział handlowy>> priv\%klient_cnf%
:: echo emailAddress=%email%>> priv\%klient_cnf%
echo [ smime ]>> priv\%klient_cnf%
echo basicConstraints = critical,CA:FALSE>> priv\%klient_cnf%
echo keyUsage = critical,digitalSignature,keyEncipherment>> priv\%klient_cnf%
echo extendedKeyUsage = clientAuth,emailProtection>> priv\%klient_cnf%
echo subjectKeyIdentifier = hash>> priv\%klient_cnf%
echo authorityKeyIdentifier = keyid:always,issuer:always>> priv\%klient_cnf%
echo subjectAltName = email:%email%>> priv\%klient_cnf%
:: echo subjectAltName = email:%email%, email:b@edu.pl, email:c@edu.pl>> priv\%klient_cnf%

echo.
echo ....::::  Generowanie wniosku certyfikacyjnego CSR  ::::....
%openssl% req -new -config priv\%klient_cnf% -key priv\%klient_klucz% -out priv\%klient_csr%
%openssl% req -text -noout -verify -in priv\%klient_csr% > priv\%klient_csr_inf%

echo.
echo ....::::  Generowanie s/n  ::::....
%openssl% rand -hex 15 > priv\%serial1%

echo.
echo ....::::  Podpisanie CSR przez certyfikat Root CA  ::::....
%openssl% x509 -req -days %client_waznosc_dni% -%skrot% -in priv\%klient_csr% -CA priv\%root_crt% -CAserial priv\%serial1% -CAkey priv\%root_klucz% -out priv\%klient_crt% -extfile priv\%klient_cnf% -extensions smime
%openssl% x509 -in priv\%klient_crt% -text -noout > priv\%klient_crt_inf%

echo.
echo ....::::  Tworzenie kluczy publicznych w folderze pub\  ::::....
:: .p7b importuje dobrze Windows (Outlook 2007), gpgsm
%openssl% crl2pkcs7 -nocrl -certfile priv\%klient_crt% -certfile priv\%root_crt% -out pub\%klucz_publiczny%
:: Thunderbird nie widzi certyfikatu root (w bundled cert.), więc trzeba najpierw importować root, potem certyfikat dla e-maila
:: https://security.stackexchange.com/a/31778
:: https://stackoverflow.com/q/49631802
:: co z security.enterprise_roots.enabled ?
%openssl% x509 -in priv\%root_crt% > pub\%klucz_publiczny_th1%
%openssl% x509 -in priv\%klient_crt% > pub\%klucz_publiczny_th2%



echo.
echo ....::::  Zapis skrotow klucza (odciskow) w pub\%fingerprint%  ::::....
echo Odcisk klucza "%cn%" [główny] :> pub\%fingerprint%
%openssl% x509 -noout -fingerprint -sha256 -inform pem -in priv\%root_crt%>> pub\%fingerprint%
%openssl% x509 -noout -fingerprint -sha1 -inform pem -in priv\%root_crt%>> pub\%fingerprint%
echo.>> pub\%fingerprint%
echo Odcisk klucza "%email%" [podrzędny] :>> pub\%fingerprint%
%openssl% x509 -noout -fingerprint -sha256 -inform pem -in priv\%klient_crt%>> pub\%fingerprint%
%openssl% x509 -noout -fingerprint -sha1 -inform pem -in priv\%klient_crt%>> pub\%fingerprint%

pushd pub\
%openssl% dgst -r -sha256 %klucz_publiczny%>%checksum%
%openssl% dgst -r -sha256 %fingerprint%>>%checksum%
%openssl% dgst -r -sha256 %klucz_publiczny_th1%>>%checksum%
%openssl% dgst -r -sha256 %klucz_publiczny_th2%>>%checksum%
popd

mkdir %klucz_do_uzytku_wewnetrznego%
echo.
echo ....::::  Tworzenie klucza prywatnego TYLKO dla WLASNEGO UZYTKU  ::::....
echo ....
echo .... plik zostanie zapisany w katalogu %klucz_do_uzytku_wewnetrznego%
echo .... pod nazwa %klucz_do_uzytku_wewnetrznego_nazwa%
echo ....
echo .... NIE UDOSTEPNIAJ GO NIKOMU !
echo ....
echo .... wygeneruje sie haslo (znajdziesz je w %pass%)
echo .... bedzie potrzebne w programie pocztowym przy imporcie klucza.
echo ....
echo .... ZAPISZ JE na kartce albo skorzystaj z menadzera
echo .... hasel np. KeePassXC itp.
echo ....
echo .... po wygenerowaniu klucza usun ten plik! [Shift+Delete]
echo ....
echo .... -------- %pass% --------
echo ....
:: lepsze zabezpieczenie, ale nie wszystkie programy otwierają, zamiast (-descert -macalg SHA1)
:: -certpbe AES-256-CBC -keypbe AES-256-CBC -macalg SHA512
:: musi być -macalg SHA1 bo nie otworzy w Win7 (wprowadzone hasło jest niepoprawne)
::
:: %openssl% pkcs12 -export -name "%email%" -descert -macalg SHA1 -in priv\%klient_crt% -inkey priv\%klient_klucz% -certfile priv\%root_crt% -out %klucz_do_uzytku_wewnetrznego%\%klucz_do_uzytku_wewnetrznego_nazwa%
::
:: https://stackoverflow.com/a/18830742
:: https://stackoverflow.com/a/17284371
%openssl% pkey -in priv\%klient_klucz%>> tmp\kombajn
%openssl% x509 -in priv\%klient_crt%>> tmp\kombajn
%openssl% x509 -in priv\%root_crt%>> tmp\kombajn
:: https://superuser.com/a/724987
%openssl% rand -base64 15 > %pass%
%openssl% pkcs12 -export -name "%email%" -descert -macalg SHA1 -in tmp\kombajn -out %klucz_do_uzytku_wewnetrznego%\%klucz_do_uzytku_wewnetrznego_nazwa% -passout file:%pass%
echo ....
echo ....::::  zrobione!  ::::....
echo ....
echo ....
echo ....::::  Ustawienia  ::::....
echo ....
echo .... domyslne ustawienia:
echo .... RSA2048/sha256, waznosc klucza: 10 lat
echo ....
echo .... ustawienia UZYTKOWNIKA:
echo .... RSA%dlugosc_klucza%/%skrot%, waznosc klucza: %client_waznosc_dni% dni 
echo ....
echo .... %email%
echo .... %o%
echo .... %cn%
echo ....
echo ....
echo ....::::  Informacja  ::::....
echo ....
echo ....
echo ....
echo ....      %klucz_do_uzytku_wewnetrznego_nazwa%
echo ....      Klucz .p12 -- import w twoich programach pocztowych
echo ....
echo .... import .p12 dziala bezproblemowo w Windows, sprawdzono z Win7, Win10
echo .... start -- uruchom -- Certmgr.msc
echo .... W Kreatorze importu certyfikatow, w Opcjach importu zaznacz:
echo .... * Oznacz ten klucz jako eksportowalny. Pozwoli to...
echo ....
echo .... W Outlook 2007:
echo .... Centrum zaufania -- Importuj, plik importu [.p12]. Dodatkowo zaznacz:
echo .... * Szyfruj tresc i zalaczniki wysylanych wiadomosci
echo .... * Dodaj podpis cyfrowy do wysylanych wiadomosci
echo ....
echo .... w Thunderbird 91, najpierw trzeba dodac .p12 w Menadzerze
echo .... certyfikatow -- Uzytkownik -- Importuj, nastepnie trzeba wejsc
echo .... w zakladke "Organy certyfikacji", wybrac swoja nazwe, kliknac
echo .... "Edytuj ustawienia zaufania" i zaznaczyc "certyfikat identyfikuje
echo .... uzytkownikow poczty"; nastepnie wybrac certyfikaty S/MIME w menu
echo .... Szyfrowanie "end-to-end" i zaznaczyc "Domyslnie dodawaj moj
echo .... podpis cyfrowy" i "Domyslnie wymagaj szyfrowania"
echo ....
echo .... Kleopatra/gpgsm 2.2.27 -- Najlepiej zrobic to przez cmd:
echo .... gpgsm -v --import %klucz_do_uzytku_wewnetrznego_nazwa%
echo .... w Kleopatrze certyfikat wyswietli sie w "Certyfikaty X509"
echo ....
echo ....
echo ....
echo ....      pub\%klucz_publiczny%
echo ....      Klucz publiczny -- eksport do innych osob
echo ....      pub\%klucz_publiczny_th1% -- [Thunderbird]
echo ....      pub\%klucz_publiczny_th2% -- [Thunderbird]
echo ....
echo .... przeslij go klientom, znajomym. Musza zaimportowac go w swoich
echo .... programach. Porownajcie odciski klucza z pliku pub\%fingerprint%
echo .... kazdy znak w tym odcisku ma znaczenie. Programy wyciagaja skrot
echo .... na bazie wygenerowanego klucza. Jesli klucz jest podrobiony,
echo .... wyswietlony zostanie INNY odcisk (skrot) od tego z pliku
echo .... pub\%fingerprint%
echo ....
echo .... MS Outlook/Windows pokazuje skrot SHA-1
echo .... Mozilla SHA-1 i SHA-256
echo .... Kleopatra SHA-1
echo ....
echo .... W Windows/Office importuj plik pub\%klucz_publiczny%. "Zainstaluj
echo .... certyfikat".
echo ....
echo .... W Kleopatra importuj plik pub\%klucz_publiczny%.
echo ....
echo .... W Thunderbird w "Menadzerze certyfikatow" wybierz zakladke "Organy
echo .... certyfikacji" i importuj plik pub\%klucz_publiczny_th1%. Zaznacz
echo .... "Zaufaj temu CA przy identyfikacji uzytkownikow poczty". Teraz
echo .... wejdz w zakladke "Osoby" i importuj plik
echo .... pub\%klucz_publiczny_th2%.
echo ....
echo ....
echo ....
echo .... Jesli zaimportowales %klucz_do_uzytku_wewnetrznego_nazwa% na swoim komputerze,
echo .... NIE MUSISZ importowac klucza publicznego!
echo ....

:: https://man.openbsd.org/openssl
:: https://www.phildev.net/ssl/opensslconf.html
:: http://www.zpcir.ict.pwr.wroc.pl/~witold/unixintro/osslintro_s.pdf
:: https://web.archive.org/web/20220214230505/https://silo.tips/downloadFile/elementy-zaczerpnite-z-encryption-security-tutorial-peter-gutmann
:: http://lab.kti.gda.pl/pki/PKI-Instrukcja.pdf
:: https://web.archive.org/web/20120525041714/http://www.tc.umn.edu:80/~brams006/selfsign.html
:: https://pg.edu.pl/documents/1112617/28513726/Public%20Key%20Infrastructure.pdf
:: https://www.digitalocean.com/community/tutorials/openssl-essentials-working-with-ssl-certificates-private-keys-and-csrs
:: https://www.ionos.com/digitalguide/e-mail/e-mail-security/smime-the-standard-method-for-e-mail-encryption/
:: https://kb.mozillazine.org/Getting_an_SMIME_certificate
:: https://www.schneier.com/wp-content/uploads/2016/02/paper-pki.pdf
echo.
echo .... mozesz teraz zamknac to okno
pause
