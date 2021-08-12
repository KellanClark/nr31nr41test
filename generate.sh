rgbasm -o main.o main.s
rgblink -o test.gb main.o
rgbfix -v -p 0 test.gb
