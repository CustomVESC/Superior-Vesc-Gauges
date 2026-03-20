# SuperiorGauges – Zaawansowany ekran wskaźników dla VESC Tool

Zamiennik domyślnego ekranwu RT Data w VESC Tool, zaprojektowany dla rowerów elektrycznych, elektrycznych hulajnóg i innych pojazdów opartych na sterownikach VESC. W repozytorium znajdują się również dwa skrypty LispBM do sterowania lampką STOP.
![Screenshot_2026-03-20-20-36-06-875_vedder vesctool](https://github.com/user-attachments/assets/82cefdfd-b35d-468f-9b85-c2a82dd8c8e7)
![Screenshot_2026-03-20-20-36-32-609_vedder vesctool](https://github.com/user-attachments/assets/1db3542f-7536-4b06-9b10-4a1a49a8d478)



---

## Ekran wskaźników – SuperiorGauges.qml

### Funkcje

- **Zegary prędkości, prądu fazowego, prądu baterii i mocy** z automatycznym doborem zakresu z konfiguracji VESC
- **Obsługa wielu VESC przez CAN** – prąd baterii jest sumą ze wszystkich podłączonych sterowników, co sprawia że skrypt nadaje się do pojazdów dwusilnikowych
- **Mnożnik kalibracji napięcia** – koryguje niedokładność wewnętrznego pomiaru ADC sterownika VESC
- **Własna tabela SOC** – stan naładowania obliczany z definiowanej przez użytkownika krzywej napięciowej ogniwa, niezależnie od wbudowanego algorytmu VESC. Domyślna krzywa: Sony VTC6
- **Szacowanie zasięgu** i zużycie energii (Wh/km lub Wh/mi)
- **Temperatury ESC i silnika** z progami ostrzegawczymi odczytywanymi z limitów konfiguracji VESC
- **Odometer, dystans przejazdu, czas działania**
- **Woltomierz** pokazujący skalibrowane napięcie pakietu

### Ekran kalibracji (resetuje się przy kazdym wyłaczeniu sterownika)
Przesuń palcem z dołu do góry na ekranie głównym, aby uzyskać dostęp do:
- Mnożnika kalibracji napięcia z przyciskami ± (krok 0.001)
- Edytowalnej tabeli napięć ogniwa

### Tabele napięć ogniw
Aby ułatwić dobór wartości do tabeli SOC dla różnych typów ogniw, przygotowana została tabela w Google Sheets zawierająca krzywe napięciowe popularnych ogniw litowo-jonowych:

📊 **[Tabela napięć ogniw – Google Sheets](https://docs.google.com/spreadsheets/d/1wsPdnuza7FB2aNU6BxtK0Lr6GHItDyqxO2WwJA4U54E/edit?usp=sharing)**

Na jej podstawie możesz odczytać napięcie ogniwa odpowiadające danemu poziomowi naładowania i wpisać je bezpośrednio do ekranu kalibracji lub do sekcji `defaultSocVoltages` w pliku QML.

### Konfiguracja domyślna
Edytuj sekcję **`USTAWIENIA DOMYŚLNE`** na początku bloku `Item {}` w pliku QML:

```qml
// Mnożnik kalibracji napięcia (1.0 = bez korekcji)
readonly property real defaultVoltageCalibMultiplier: 1.0

// Napięcia ogniwa dla 0%, 5%, 10% ... 100% SOC (domyślnie: Sony VTC6)
readonly property var defaultSocVoltages: [
//   0%     5%     10%    15%    20%    25%    30%
    3.007, 3.183, 3.323, 3.429, 3.494, 3.537, 3.583,
    ...
]
```

### Wymagania
- VESC Tool (Windows / Linux)
- Firmware VESC
---

## Skrypty lampki STOP – LispBM

Dwa skrypty LispBM do sterowania lampką STOP przez **pin PPM** (skonfigurowany jako wyjście cyfrowe). Hamowanie jest wykrywane gdy **napięcie na ADC2 przekroczy 0,95 V** (czujnik dźwigni hamulca).

### `Stop_0or1.lisp` – Lampka STOP włącz/wyłącz

Pin PPM jest **domyślnie w stanie niskim** i przechodzi w **stan wysoki tylko podczas hamowania**.

Przeznaczenie:
- Lampki z oddzielnym przewodem do sygnalizacji pozycji i hamowania
- Zestawy z oddzielnymi lampkami pozycji i STOP

| Stan | Pin PPM |
|------|---------|
| Jazda / postój | LOW |
| Hamowanie (ADC2 > 0,95 V) | HIGH |

---

### `Stop_3Hz.lisp` – Migająca lampka STOP (3 Hz)

Pin PPM jest **cały czas w stanie wysokim** i **miga z częstotliwością 3 Hz podczas hamowania**.

Przeznaczenie:
- Dwuprzewodowe lampki używające tych samych diod do sygnalizacji pozycji i hamowania
- Popularne lampki tylne hulajnóg (np. Xiaomi, Kukirin)

| Stan | Pin PPM |
|------|---------|
| Jazda / postój | HIGH (stały) |
| Hamowanie (ADC2 > 0,95 V) | Miganie 3 Hz |

---

## Instalacja

**Ekran QML:**
1. Otwórz VESC Tool
2. Przejdź do zakładki **Scripting**
3. Wczytaj plik `SuperiorGauges.qml` i kliknij **Run**

**Skrypt LispBM:**
1. Podłącz czujnik dźwigni hamulca lub manetkę regenu do pinu **ADC2**
2. Przejdź do zakładki **LispBM** w VESC Tool
3. Wczytaj odpowiedni plik `.lisp` i kliknij **Run**

---

## Licencja

GNU General Public License v3.0 – szczegóły w pliku [LICENSE](LICENSE)
