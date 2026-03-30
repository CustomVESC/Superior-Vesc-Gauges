# SuperiorGauges – Instrukcja
Najpierw trzeba wgrać Kalibracja_Napięcia.vescpkg i sprawdzić mnożnik kalibracji dla swojego sterownika.
Następnie wprowadzić tą wartość w kroku 5 oraz napięcia dla różnych poziomów naładowania w kroku 6.
Nastepnie złożyć plik QML w Vesc Package i wgrać ponownie na vesc.

---
Najpierw pobieramy plik
Kalibracja_Napięcia.vescpkg w celu sprawdzenia poprawnego mnożnika poprawiającego dokładność wskazania napięcia.

W menu start wybramy opcje package store.
![kalibracjaNapięcia_krok_1](https://github.com/user-attachments/assets/d0fde1e8-0c2f-43a0-afb4-fbd13b2d167e)
Następnie klikamy w 3 kropki w lewym dolnym rogu
![kalibracjaNapięcia_krok_2](https://github.com/user-attachments/assets/bcc654a1-ca1f-45d3-b971-9a1733dce7ed)
i wybieramy install from file
![kalibracjaNapięcia_krok_3](https://github.com/user-attachments/assets/903464e0-15da-424a-ab41-f79f1d47b434)
następnie wybieramy plik Kalibracja_Napięcia.vescpkg i go wgrywamy
Po wgraniu pokaże się dodatkowa zakładka w której zobaczymy nowe zegary a pod nimi można sprawdzić z jakim mnożnikiem na zegarze pojawi się poprawne napięcie. (Uwaga vesc przy każdym uruchomieniu będzie wracał do domyślnej wartości mnożnika napięcia i tabelki SOC dlatego trzeba je nadpisać w pliku qml.
---

Pobieramy plik SuperiorGauges.qml następnie
uruchamiamy program Vesc tool na komputerze (nie trzeba łączyć się z sterownikiem)
---
Wybieramy opcje QML scripting
<img width="1918" height="1021" alt="krok1" src="https://github.com/user-attachments/assets/ac7dedb5-3edb-465e-a829-1b7a91dba5a0" />
klikamy opcje folderu by wybrać plik .qml
<img width="1918" height="1022" alt="krok2" src="https://github.com/user-attachments/assets/414a7f9e-902a-45f0-8ec2-c5ad73ce826e" />
Wybieramy pobrany plik SuperiorGauges.qml
<img width="925" height="662" alt="krok3i4" src="https://github.com/user-attachments/assets/541e47f9-fa80-4aaf-9127-69dea6ce5a1a" />
W punkcie 5 wpisujemy mnożnik napięcia który skoryguje zakłamanie woltomierza.
W punkcie 6 poprawiamy tabelkę wskazania napięcia (na podstawie linku w ReadMe.md)
Na koniec klikamy dyskietkę w celu nadpisania zmian.
<img width="1918" height="1018" alt="krok5_6_7" src="https://github.com/user-attachments/assets/534c96fa-88d9-4253-a5f8-1c89a9e86f68" />
Wybiramy Package Store i wtedy Create Package
<img width="1918" height="1020" alt="krok8_9" src="https://github.com/user-attachments/assets/cc0e51fb-0def-470b-a25f-6b023983fe4e" />

<img width="1918" height="1018" alt="krok10_11_12_13" src="https://github.com/user-attachments/assets/01a3d1c8-39ca-4fe8-9c70-9fe297c79bf6" />
<img width="1917" height="1026" alt="krok14" src="https://github.com/user-attachments/assets/e43c94ad-fef1-437c-b0bf-e8b2f3fe50f8" />

---

![kalibracjaNapięcia_krok_1](https://github.com/user-attachments/assets/d0fde1e8-0c2f-43a0-afb4-fbd13b2d167e)
![kalibracjaNapięcia_krok_2](https://github.com/user-attachments/assets/bcc654a1-ca1f-45d3-b971-9a1733dce7ed)
![kalibracjaNapięcia_krok_3](https://github.com/user-attachments/assets/903464e0-15da-424a-ab41-f79f1d47b434)
---
