# Dodatkowe certyfikaty
plik `generowanie_smime.bat` nadaje się do tworzenia certyfikatu dla 1 adresu e-mail (na Imię i Nazwisko); ew. można dodać następne adresy jako alternatywnie "podczepione" do certyfikatu ("subjectAltName").

Co jeśli prowadzimy firmę i chcemy każdemu pracownikowi utworzyć certyfikat?

## Schemat certyfikatów dla każdego pracownika
Utworzymy listę pracowników i zrobimy listę adresów, pod które trzeba zrobić certyfikaty.

```
{
Firma sp. z o.o.
PL
Mazowieckie
Warszawa
}
```

Pracownik | stanowisko | adres e-mail
| ----------- | ----------- | ----------- |
Jan Kowalski | prezes | `jkowalski@edu.pl`
Adam Nowak | wiceprezes | `anowak@edu.pl` `szkolenia@edu.pl`
Grażyna Kowalska | sekretarka | `biuro@edu.pl`
Aneta Rachunek | księgowa | `faktury@edu.pl`
Piotr Niedopomagalski | technik it | `pomoc@edu.pl`

## Tworzenie głównego i pierwszego certyfikatu z listy (`generowanie_smime.bat`)
Trzeba **ręcznie** skonfigurować główny skrypt. Z przykładu powyżej będzie wyglądać np. tak:

### prezes ==generowanie_smime.bat==

```
{
set o=Firma sp. z o.o.
set email=jkowalski@edu.pl
...
set cn=Firma sp. z o.o. CA e-mail
...
echo ....::::  Generowanie ustawien dla Root CA  ::::....
...
echo [ root_dn ]>> priv\%root_cnf%
echo commonName=%cn%>> priv\%root_cnf%
echo organizationName=%o%>> priv\%root_cnf%
echo countryName=PL>> priv\%root_cnf%
echo stateOrProvinceName=Mazowieckie>> priv\%root_cnf%
echo localityName=Warszawa>> priv\%root_cnf%
...
echo ....::::  Generowanie ustawien dla certyfikatu e-mail  ::::....
...
echo [ client_dn ]>> priv\%klient_cnf%
echo commonName=Jan Kowalski>> priv\%klient_cnf%
echo organizationName=%o%>> priv\%klient_cnf%
echo organizationalUnitName=Prezes>> priv\%klient_cnf%
echo emailAddress=%email%>> priv\%klient_cnf%
...
echo subjectAltName = email:%email%>> priv\%klient_cnf%
}
```

## Tworzenie następnych certyfikatów e-mail (`certyfikat_pracownika.bat`)
plik `certyfikat_pracownika_....bat` musi znajdować się "obok" głównego skryptu generującego (`generowanie_smime.bat`) w folderze.

### wiceprezes ==certyfikat_pracownika_1.bat==

```
{
set cn=Adam Nowak
set o=Firma sp. z o.o.
set email=anowak@edu.pl
set alias=pracownik_1
...
echo [ client_dn ]>> %alias%\priv\%klient_cnf%
echo commonName=%cn%>> %alias%\priv\%klient_cnf%
echo organizationName=%o%>> %alias%\priv\%klient_cnf%
echo organizationalUnitName=Wiceprezes>> %alias%\priv\%klient_cnf%
echo emailAddress=%email%>> %alias%\priv\%klient_cnf%
...
echo subjectAltName = email:%email%, email:szkolenia@edu.pl>> %alias%\priv\%klient_cnf%
}
```

### sekretarka ==certyfikat_pracownika_2.bat==

```
{
set cn=Grażyna Kowalska
set o=Firma sp. z o.o.
set email=biuro@edu.pl
set alias=pracownik_2
...
echo [ client_dn ]>> %alias%\priv\%klient_cnf%
echo commonName=%cn%>> %alias%\priv\%klient_cnf%
echo organizationName=%o%>> %alias%\priv\%klient_cnf%
echo organizationalUnitName=Sekretariat>> %alias%\priv\%klient_cnf%
echo emailAddress=%email%>> %alias%\priv\%klient_cnf%
...
echo subjectAltName = email:%email%>> %alias%\priv\%klient_cnf%
}
```

### następni pracownicy ==certyfikat_pracownika_....bat== jw.

### ==Sprawdź folder `test` i przetestuj czy pliki działają na twoim urządzeniu, programie pocztowym.==


## Udostępnianie certyfikatów (kluczy publicznych) na stronie www firmy
Można to zrobić w takiej formie:

 | | adres e-mail | certyfikat Office | certyfikat Thunderbird | odcisk SHA-1
| ----------- | ----------- | ----------- | ----------- | ----------- | ----------- |
Firma sp. z o.o. |  |  | `pub/01root.crt` | `pub/fingerprint.txt`
Jan Kowalski | jkowalski@edu.pl | `pub/klucz_publiczny.p7b` | `pub/02user.crt` | `pub/fingerprint.txt`
Adam Nowak | anowak@edu.pl, szkolenia@edu.pl | `pracownik_1/pub/klucz_publiczny.p7b` | `pracownik_1/pub/02user.crt` | `pracownik_1/pub/fingerprint.txt`
Grażyna Kowalska | biuro@edu.pl | `pracownik_2/pub/klucz_publiczny.p7b` | `pracownik_2/pub/02user.crt` | `pracownik_2/pub/fingerprint.txt`
Aneta Rachunek | faktury@edu.pl | `pracownik_3/pub/klucz_publiczny.p7b` | `pracownik_3/pub/02user.crt` | `pracownik_3/pub/fingerprint.txt`
Piotr Niedopomagalski | pomoc@edu.pl | `pracownik_4/pub/klucz_publiczny.p7b` | `pracownik_4/pub/02user.crt` | `pracownik_4/pub/fingerprint.txt`

Będzie to wyglądać mniej więcej tak:

 | | adres e-mail | certyfikat Office | certyfikat Thunderbird | odcisk SHA-1
| ----------- | ----------- | ----------- | ----------- | ----------- | ----------- |
Firma sp. z o.o. |  |  | [Cert. główny](/firma.crt) | `B9:34:D9:18:12:7B:89:1D:44:DF:E8:62:1F:88:41:B8:47:E5:FB:53`
Jan Kowalski | jkowalski@edu.pl | [p7b](/jkowalski.p7b) | [crt](/jkowalski.crt) | `B4:F7:27:92:7F:1F:A2:5A:AC:12:EC:FA:E0:F2:1A:41:98:35:04:37`
Adam Nowak | anowak@edu.pl, szkolenia@edu.pl | [p7b](/anowak.p7b) | [crt](/anowak.crt) | `D6:96:44:C2:EF:E6:DA:31:58:60:D2:C6:61:7E:51:3E:6C:CD:55:03`
Grażyna Kowalska | biuro@edu.pl | [p7b](/biuro.p7b) | [crt](/biuro.crt) | `43:02:6E:C3:CE:73:2F:E1:30:FB:62:77:C2:C4:B5:87:1B:5D:CA:3B`
Aneta Rachunek | faktury@edu.pl | [p7b](/faktury.p7b) | [crt](/faktury.crt) | `2E:DC:7C:B6:02:29:00:A0:B9:F3:96:0A:4D:78:7D:12:BF:44:33:2B`
Piotr Niedopomagalski | pomoc@edu.pl | [p7b](/pomoc.p7b) | [crt](/pomoc.crt) | `C9:C7:51:19:88:0E:E9:9C:EB:66:B4:29:34:B9:ED:36:6F:20:82:7B`

## [Dodatkowe bezpieczeństwo] Stosuj klucze zewnętrzne Yubico/Nitrokey
Dla każdego pracownika kup klucz (crypto-stick). Nie przenoś klucza prywatnego (.==p12==, katalog ==priv==) na urządzenia codziennego użytku. Podczas tworzenia kluczy użyj dedykowanego komputera nie podłączonego pod internet np. Live-CD z oprogramowaniem do kopiowania kluczy na crypto-sticka. Zachowaj kopie wygenerowanych plików w bezpiecznym miejscu np. na pendrive; nie podłączaj go do komputera codziennego użytku.

![nie bądź januszem](janusz.jpg)
