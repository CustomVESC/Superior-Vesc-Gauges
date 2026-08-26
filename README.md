---

## Superior Gauges – Zaawansowany ekran wskaźników dla VESC Tool

Zamiennik domyślnego ekranu RT Data w VESC Tool, zaprojektowany dla rowerów elektrycznych, elektrycznych hulajnóg i innych pojazdów opartych na sterownikach VESC.

**Wersja V3** to pełne przepisanie projektu na architekturę **LispBM (backend na sterowniku) + QML (interfejs w telefonie)**. W przeciwieństwie do wersji 2 (czysty QML), wszystkie ustawienia żyją teraz w pamięci sterownika — przetrwają zamknięcie aplikacji, a wszystkie zmiany robi się bezpośrednio w apce, bez dotykania kodu na komputerze. Lampka STOP jest teraz wbudowana w główny skrypt, nie wymaga osobnego pliku.

---

## Ekran wskaźników

### Ekran 1 – Główne zegary

- Prąd fazowy, moc, prąd baterii, prędkość, napięcie, temperatura sterownika i silnika, zużycie energii
- **Prąd baterii i moc sumowane ze wszystkich podłączonych sterowników** (pojazdy dwusilnikowe)
- Zegar baterii z SOC i pozostałym zasięgiem
- Słupki wciśnięcia gazu i hamulca
- Przebieg, trasa, czas pracy
- Efekt „wymiatania" wskazówek trwający podczas ładowania danych skryptu

### Ekran 2 – Statystyki jazdy

- SOC na początku jazdy i zużycie od tego momentu
- Zużycie energii (Wh/km) liczone z SOC, oraz osobno z ostatnich 2 km wg VESC
- Zasięg pozostały i zasięg 100–0%, liczone z tabelki SOC którą można dostosować pod swoją baterię
- Maksymalny prąd baterii i prąd fazowy osobno dla każdego sterownika
- Maksymalna moc, maksymalna rekuperacja, maksymalne i minimalne napięcie zarejestrowane podczas jazdy
- **Guzik trybu Legal** — jeden przycisk włączający/wyłączający ograniczenia prędkości, mocy i prądu; działa poprawnie na pojazdach jedno- i dwusilnikowych, automatycznie zapamiętuje i przywraca oryginalne ustawienia obu sterowników

### Ekran 3 – Sterowanie

- **Lampka STOP** — 3 tryby (wyłączona / zapala się przy hamowaniu / świeci stale i miga przy hamowaniu), próg aktywacji ustawiany suwakiem jako % wciśnięcia hamulca
- Możliwość zmiany ustawień trybu Legal

### Ekran 4 – Ustawienia

- Mnożnik kalibracji napięcia — korekta niedokładności pomiaru napięcia mierzonego przez sterownik
- Własna, edytowalna tabela SOC (krzywa napięciowa ogniwa) — bez potrzeby edycji kodu
- Zapis ustawień do pamięci trwałej sterownika (EEPROM)

---

### Trwałość ustawień

Wszystkie ustawienia (próg lampki STOP, limity trybu Legal, kalibracja napięcia, tabela SOC) żyją w pamięci RAM sterownika — **przetrwają zamknięcie i ponowne otwarcie aplikacji**, niezależnie od telefonu. Żeby przetrwały też **fizyczny restart sterownika**, trzeba je dodatkowo zapisać do EEPROM przyciskiem „Zapisz ustawienia" na ekranie 3 lub 4.

---

### Obsługa wielu sterowników

Prąd baterii, moc i statystyki maksimów sumują/śledzą dane z **obu** sterowników w pojeździe dwusilnikowym (CAN). Tryb Legal aplikuje limity osobno na każdym sterowniku i przywraca każdemu jego własne, oryginalne ustawienia — nie zakłada że oba mają identyczną konfigurację.

---

### Znane ograniczenia

- **Reset do domyślnych** (ekran 4) resetuje tylko pamięć RAM sterownika — żeby przetrwało restart, trzeba po nim dodatkowo kliknąć „Zapisz ustawienia"
- **Po każdym wgraniu pakietu** może być konieczne jednorazowe kliknięcie `restart lispbm` w terminalu VESC Tool, żeby LispBM poprawnie wystartował przy kolejnym uruchomieniu sterownika (znane ograniczenie firmware od wersji 6.06)


---

### Tabele napięć ogniw

Aby ułatwić dobór wartości do tabeli SOC dla różnych typów ogniw, dostępna jest tabela w Google Sheets z krzywymi napięciowymi wielu modeli ogniw litowo-jonowych:

📊 **[Tabela napięć ogniw – Google Sheets](https://docs.google.com/spreadsheets/d/1wsPdnuza7FB2aNU6BxtK0Lr6GHItDyqxO2WwJA4U54E/edit?usp=sharing)**

Na jej podstawie możesz odczytać poziom naładowania odpowiadający danemu napięciu ogniwa i wpisać go bezpośrednio na ekranie 4.

---

### Wymagania

- VESC Tool na android, Windows, Mac lub Linux, 
- sterownik z firmware 6.06 lub wyższym
- Multimetr lub smartBMS (do weryfikacji prawidłowego napięcia przy kalibracji)

---

## Instalacja

Repozytorium zawiera dwa pakiety:

- **`SuperiorGauge_V3.0.vescpkg`** — główny pakiet (ekran wskaźników + cała logika). Wgraj na sterownik **tylny (master)**.
- **`SlaveVESC.vescpkg`** — tylko przy **pojazdach dwusilnikowych**: wgraj na sterownik **przedni (slave)**, żeby odczytać z niego prąd fazowy.

Pliki z poprzedniej wersji (v2) znajdują się w folderze `stary skryptV2`, zachowane archiwalnie.

Pełna instrukcja krok po kroku: 📖 [Instrukcja instalacji](Instrukcja.md)

---

## Licencja

GNU General Public License v3.0 – szczegóły w pliku [LICENSE](LICENSE)

---
