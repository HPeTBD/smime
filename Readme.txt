Generowanie własnego klucza S/MIME.
v2 23/03/2022

· kompaktowe rozwiązanie: skrypt potrzebuje tylko openssl.exe
· wysyłaj szyfrowane maile dowolnym (praktycznie) programem pocztowym

Edytuj (Notatnikiem systemowym) "generowanie_smime.bat" :

1. ustaw ścieżkę do OpenSSL:
   set openssl="..."

2. ustaw Imię/Nazwisko/nazwę firmy itp.:
   set o=

3. ustaw adres e-mail (tylko 1 adres):
   set email=

4. ustaw datę ważności (ile dni):
   set client_waznosc_dni=

Uruchom skrypt!

Screeny: 01,02,03.png

Licencja: MIT/ISC/BSD
