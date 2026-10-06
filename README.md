## Superior Gauges: ekran wskaźników dla VESC Tool

Superior Gauges to zamiennik domyślnego ekranu RT Data w VESC Tool. Zrobiłem go z myślą o rowerach elektrycznych, hulajnogach i innych pojazdach używających sterowników VESC.

### Co nowego

**V3.0** to projekt napisany od nowa. Logika działa teraz na sterowniku, a telefon odpowiada tylko za wyświetlanie zegarów. W praktyce oznacza to, że ustawienia siedzą w pamięci sterownika i nie znikają po zamknięciu aplikacji. Wszystko zmienia się bezpośrednio w apce, bez grzebania w kodzie na komputerze. Lampka STOP jest już częścią głównego skryptu, więc nie trzeba wgrywać osobnego pliku.

**V3.1** przynosi zmiany w tempomacie. Przy zegarach pojawiła się kontrolka pokazująca jego stan, a w ustawieniach można wybrać jeden z czterech trybów:

- **Bez zmian:** działa oryginalny tempomat z VESC
- **Przycisk bistabilny:** tempomat włączany i wyłączany przyciskiem z zatrzaskiem
- **Przycisk monostabilny:** tempomat włączany zwykłym przyciskiem chwilowym
- **Aktywacja po czasie:** tempomat włącza się, gdy gaz jest trzymany w jednej pozycji przez kilka sekund (od 1 do 6 s, ustawiane suwakiem)

W trybach z przyciskiem tempomat wyłącza się po wciśnięciu hamulca, a gazem można w trakcie regulować prędkość. W trybie aktywacji po czasie tempomat wyłącza się po ruszeniu gazem albo hamulcem.

---

## Ekran wskaźników

<img width="864" height="1920" alt="VID_20260826_112219" src="https://github.com/user-attachments/assets/f946f95e-e01d-43fc-b037-c8e3c7119330" />

### Ekran 1: główne zegary

- prąd fazowy, moc, prąd baterii, prędkość, napięcie, temperatura sterownika i silnika, zużycie energii
- prąd baterii i moc są sumowane ze wszystkich sterowników, więc w pojazdach dwusilnikowych widać łączne wartości
- zegar baterii z poziomem naładowania (SOC) i pozostałym zasięgiem
- paski pokazujące, jak mocno wciśnięty jest gaz i hamulec
- przebieg, trasa i czas pracy
- efekt „wymiatania" wskazówek, który trwa, dopóki skrypt ładuje dane
- kontrolka stanu tempomatu

### Ekran 2: statystyki jazdy

- SOC na początku jazdy i ile od tego czasu ubyło
- zużycie energii w Wh/km, liczone na dwa sposoby: z SOC oraz z ostatnich 2 km według VESC
- pozostały zasięg i zasięg od 100 do 0%, liczone z tabeli SOC, którą można dopasować do swojej baterii
- maksymalny prąd baterii i prąd fazowy, osobno dla każdego sterownika
- maksymalna moc, maksymalna rekuperacja oraz najwyższe i najniższe napięcie z całej jazdy
- **przycisk trybu Legal:** jednym kliknięciem można włączyć/wyłączyć ograniczenia prędkości, mocy i prądu. Działa przy jednym i dwóch silnikach.

### Ekran 3: ustawienia

- **lampka STOP** z trzema trybami: wyłączona, zapalana przy hamowaniu albo świecąca cały czas i migająca przy hamowaniu. Próg zadziałania ustawia się suwakiem jako procent wciśnięcia hamulca
- ustawienia limitów trybu Legal
- wybór trybu tempomatu
- mnożnik kalibracji napięcia, gdy sterownik mierzy je trochę niedokładnie
- własna tabela SOC (krzywa napięcia ogniwa), którą można edytować
- zapis ustawień do pamięci trwałej sterownika (EEPROM)

---

### Zapisywanie ustawień

Wszystkie ustawienia (próg lampki STOP, limity trybu Legal, tryb tempomatu, kalibracja napięcia, tabela SOC) są trzymane w pamięci RAM sterownika. Dzięki temu zostają po zamknięciu i ponownym otwarciu aplikacji, niezależnie od telefonu. Jeśli mają przetrwać też wyłączenie lub restart sterownika, trzeba je zapisać do EEPROM przyciskiem „Zapisz ustawienia" na ekranie 3.

---

### Dwa sterowniki

W pojeździe dwusilnikowym (połączenie CAN) prąd baterii, moc i statystyki maksimów są liczone z obu sterowników. Tryb Legal ustawia limity na każdym sterowniku osobno i każdemu przywraca jego własną konfigurację, więc oba nie muszą być ustawione tak samo.

---

### Znane ograniczenia

- Przycisk „Reset do domyślnych" na ekranie 3 czyści tylko pamięć RAM. Żeby reset przetrwał restart sterownika, trzeba potem jeszcze kliknąć „Zapisz ustawienia".
- Po wgraniu pakietu czasem trzeba raz wpisać `restart lispbm` w terminalu VESC Tool, żeby LispBM normalnie wystartował przy kolejnym uruchomieniu sterownika. To ograniczenie firmware, występuje od wersji 6.06.

---

### Tabele napięć ogniw

Żeby łatwiej było uzupełnić tabelę SOC, przygotowałem arkusz z krzywymi napięcia dla wielu popularnych ogniw litowo-jonowych:

**[Tabela napięć ogniw (Google Sheets)](https://docs.google.com/spreadsheets/d/1wsPdnuza7FB2aNU6BxtK0Lr6GHItDyqxO2WwJA4U54E/edit?usp=sharing)**

Wystarczy znaleźć w niej swoje ogniwo, odczytać, jakiemu poziomowi naładowania odpowiada dane napięcie, i wpisać wartości na ekranie 3.

---

### Wymagania

- VESC Tool na Androida, Windowsa, Maca lub Linuksa
- sterownik z firmware 6.06 lub nowszym
- multimetr albo smartBMS, żeby sprawdzić rzeczywiste napięcie przy kalibracji

---

## Instalacja

W repozytorium są dwa pakiety:

- **`SuperiorGauge_V3.0.vescpkg`**: główny pakiet z ekranem wskaźników i całą logiką. Wgrywa się go na **tylny sterownik (master)**.
- **`SlaveVESC.vescpkg`**: potrzebny tylko w **pojazdach dwusilnikowych**. Wgrywa się go na **przedni sterownik (slave)**, żeby dało się odczytać z niego prąd fazowy.

Pliki z poprzedniej wersji (V2) zostały dla porządku zachowane w folderze `StarySkryptV2`.

Dokładna instrukcja krok po kroku: [Instrukcja instalacji](Instrukcja.md)

---

## Licencja

GNU General Public License v3.0, szczegóły w pliku [LICENSE](LICENSE)

---

Skrypt powstał z pomocą [Claude.ai](https://claude.ai).
