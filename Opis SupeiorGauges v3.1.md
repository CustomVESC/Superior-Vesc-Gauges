# Superior Gauges

Ekran wskaźników dla VESC Tool (zamiennik RT Data) z lampką STOP, tempomatem z przyciskiem i bez, trybem Legal i statystykami jazdy. Dla rowerów elektrycznych, hulajnóg i innych pojazdów z VESC, z jednym sterownikiem lub z dwoma (master + slave po CAN).

Pełny opis i pliki: [SuperiorGauges github](https://github.com/CustomVESC/Superior-Vesc-Gauges)

**Uwaga!** 
Wymagany firmware 6.06 lub nowszy. Do tempomatu musi być włączona opcja Enable Cruise Control (App Config → ADC → General).

## Instalacja

Pakiet wgrywa się na tylny sterownik (master). W pojeździe dwusilnikowym pakiet slave wgrywa się na przedni. Po wgraniu każdego pakietu trzeba od razu zrobić `restart lispbm` w terminalu VESC Tool.

## Ekrany

**Zegary**  
Prąd, moc, prędkość, napięcie, temperatury, bateria z zasięgiem, słupki gazu i hamulca oraz kontrolka tempomatu. W pojeździe dwusilnikowym prąd i moc są sumowane z obu sterowników.

**Statystyki**  
SOC, zużycie Wh/km, zasięg oraz maksima prądów, mocy i napięć. Tutaj też jest przycisk trybu Legal, który jednym kliknięciem ogranicza prędkość, moc i prąd.

**Ustawienia**  
Lampka STOP, limity trybu Legal, tempomat, kalibracja napięcia i tabela SOC. Po każdej zmianie trzeba je zapisać przyciskiem na samym dole skryptu.

## Tempomat

Hamulec wyłącza tempomat w każdym trybie.

**Brak zmian**  
Oryginalne zachowanie tempomatu VESC, aktywowane zwarciem TX z GND.

**Przycisk bistabilny**  
Tempomat jest aktywny tylko, gdy przycisk jest wciśnięty. Włącza go zwarcie TX z GND, a wyłącza puszczenie przycisku.

**Przycisk monostabilny**  
Krótkie zwarcie TX do GND włącza, kolejne wyłącza. Zwarcie dłuższe niż 5 s wyłącza tempomat.

**Aktywacja po czasie**  
Tempomat włącza się po trzymaniu gazu przez ustawiony czas (1 do 6 s). Wyłącza go gaz albo hamulec.

Zmiana trybu z Brak zmian na inny wymaga zapisu ustawień i ponownego uruchomienia sterownika.

## Podłączenia

Obie rzeczy są opcjonalne.

**Przycisk tempomatu**  
Przycisk zwierny (NO), bistabilny lub monostabilny, między TX a GND.

**Lampka STOP**  
Wyjście PPM daje 3,3V i bardzo mały prąd, więc trzeba użyć modułu przekaźnika albo MOSFET-a z optoizolacją, który ma wejście sterowane 3,3V i dopiero nim zasilać lampkę. Tryb lampki (wyłączona, przy hamowaniu, stale z mruganiem przy hamowaniu) i próg zapalenia ustawia się w ustawieniach. 

## Changelog

**Wersja 3.1**
* Tempomat w czterech trybach, w tym z fizycznym przyciskiem na TX

**Wersja 3.0**
* Edycja ustawień wewnątrz skryptu
* Statystyki zapisywane w RAM sterownika, a nie telefonu jak w wersji 2.0 (przypadkowe wyjście z aplikacji nie resetuje statystyk)
* Animacja wskazówek przy uruchamianiu skryptu
* Interfejs po polsku
* Poprawione działanie wirtualnego przycisku Legal (wyświetlanego na ekranie telefonu)
* Wbudowany skrypt lampki STOP