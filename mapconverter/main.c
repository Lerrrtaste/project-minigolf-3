/*
 * Example input file:
 * guru4.track:
    V 2
    A Zwan
    N Guru 4
    T BIAQBAQQ46DBJAQBAQQDBSAQ44DEDEBRAQIH42DBJAQBTAQ3EGBIQAB3A23DBJQAEBIQAB3ADBJQAEDBIQAB3ADBJQAEBIQAB3ADDBJQAF5EB3A25DEG3DEDB3A3DEGDCBAED7E25DEE3DEDE3DEE4D7E7DBMAQE10DBMAQE4DEE3DBLAQBKAQE3DEEBPAQBJAQED7E7DBAQQE10DBAQQE4DEE9DEEDBAQQED7E7DEE10DEE4DEE9DEEDEED7E7DEE10DEE4DEE9DEEDEED6EBLQAE6DEBLQAE8DBKQAEE4DEE9DEEDEED6E3DBNAQE3DBLAQF10DBKAQE4DEE3DBIAQBJAQE3DEEDEED6EBIQAH10DBJQAEDDBIQAH8DEE3DBAQQDE3DEEDEED6EB3A12DEDDB3A9DEE3DEDE3DEEDEED7E12DEDDE9DEE3DEDE3DEEDEED7E12DEDDE8DBKQAEBLQAEDDEDE3DEEDEED7E3DBPAQBAQQDDBJAQE3DEDDE3DBPAQBAQQ6DBNAQEDEDE3DEEDBLAQBNAQ8E6DBJQAFE3DEDDE8DBJQAEBIQAHDDEDE3DEE4D7E7DEE3DEDDE9DBOAQG3DEDE3DBOAQE4D7E7DEE3DEDDE14DEDE9D7E7DEE3DEDDE14DEDE9D6EBLQAE4DCAABKQAEBLQAEDBKQAEDDBLQAE12DBKQAEDBLQAE7DBKQA5EBLAQF42DBKAQ3EDBQAQ44DBAQQDBLAQE46DI,Ads:B1504
    C 1,2
    I 98753,1075491,3,22
    R 359,115,126,163,253,790,598,507,387,294,1840
    B nekro,1115071200000
*/

/*
 * Things to do
 *
 * 0. Read file
 *
 * 1. Decompress
 *
 * 2. Convert to Tile Codes
 * Tile code:   (isSpecial << 24) | (shapeIndex << 16) | (backgroundElementIndex << 8) | foregroundElementIndex
 *
 * 3. Convert to Tile Names
 *
 * 4. Export File
*/

// include file io libraries
#include <iostream>
#include <fstream>

using namespace std;


int method123(string input, int cursor) {
  string var3 = "";

  while(true) {
    char var4 = input[cursor];
    if(var4 < '0' || var4 > '9') {
      return (var3 == "") ? 1 : atoi(var3.c_str());
    }

    if(var3 == "") {
      var3 = string(1, var4);
    } else {
      var3 += var4;
    }

    ++cursor;
  }
}

string expandMap(string mapString) {

  int length = mapString.length();
  string buffer;

  for(int cursor = 0; cursor < length; ++cursor) {
    int var5 = method123(mapString, cursor);
    if(var5 >= 2) {
      ++cursor;
    }
    if(var5 >= 10) {
      ++cursor;
    }
    if(var5 >= 100) {
      ++cursor;
    }
    if(var5 >= 1000) {
      ++cursor;
    }
    char var6 = mapString[cursor];

    for(int var7 = 0; var7 < var5; ++var7) {
      buffer += var6;
    }
  }

  return buffer;
}


string decompress(string mapString) {
  string mapStringExpanded = expandMap(mapString);

  return mapStringExpanded;
}

int mapTiles[49][25];
void parseMap(string data) {
  /*
   *
        String mapData = data;
        int cursorIndex = 0;

        int tileX;
        for (int tileY = 0; tileY < 25; ++tileY) {
            for (tileX = 0; tileX < 49; ++tileX) {

                int currentMapIndex = mapChars.indexOf(mapData.charAt(cursorIndex));

                if (currentMapIndex <= 2) {  // if input= A,B or C
                    int mapcursor_one_ahead;
                    int mapcursor_two_ahead;
                    int mapcursor_three_ahead;

                    if (currentMapIndex == 1) { // if input = B.
                        mapcursor_one_ahead = mapChars.indexOf(mapData.charAt(cursorIndex + 1));
                        mapcursor_two_ahead = mapChars.indexOf(mapData.charAt(cursorIndex + 2));
                        mapcursor_three_ahead = mapChars.indexOf(mapData.charAt(cursorIndex + 3));
                        cursorIndex += 4;
                    } else { // if input = A or C
                        mapcursor_one_ahead = mapChars.indexOf(mapData.charAt(cursorIndex + 1));
                        mapcursor_two_ahead = mapChars.indexOf(mapData.charAt(cursorIndex + 2));
                        mapcursor_three_ahead = 0;
                        cursorIndex += 3;
                    }

                    // (currentMapIndex << 24) + (mapcursor_one_ahead << 16) + (mapcursor_two_ahead << 8) + mapcursor_three_ahead;
                    this.mapTiles[tileX][tileY] = currentMapIndex * 256 * 256 * 256 + mapcursor_one_ahead * 256 * 256 + mapcursor_two_ahead * 256 + mapcursor_three_ahead;
                } else {

                    if (currentMapIndex == 3) {  // if input = D
                        this.mapTiles[tileX][tileY] = this.mapTiles[tileX - 1][tileY]; // tile to west is same as current
                    }

                    if (currentMapIndex == 4) { // if input = E;
                        this.mapTiles[tileX][tileY] = this.mapTiles[tileX][tileY - 1]; // tile to the north is same as current
                    }

                    if (currentMapIndex == 5) { // if input = F;
                        this.mapTiles[tileX][tileY] = this.mapTiles[tileX - 1][tileY - 1]; // tile to the northwest is same as current
                    }

                    if (currentMapIndex == 6) {  // if input = G;
                        this.mapTiles[tileX][tileY] = this.mapTiles[tileX - 2][tileY]; // 2 tiles west is same as current (skip a tile to the left)
                    }

                    if (currentMapIndex == 7) { // if input = H
                        this.mapTiles[tileX][tileY] = this.mapTiles[tileX][tileY - 2]; // 2 tiles north is same as current (skip the tile above)
                    }

                    if (currentMapIndex == 8) { // if input= I
                        this.mapTiles[tileX][tileY] = this.mapTiles[tileX - 2][tileY - 2]; // 2 tiles northwest is same as current (skip the diagonal)
                    }

                    ++cursorIndex;
                }
            }
   */
    string mapData = data;
    int cursorIndex = 0;
    string mapChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

    int tileX;
    for(int tileY = 0; tileY < 25; ++tileY) {
        for(tileX = 0; tileX < 49; ++tileX) {
            int currentMapIndex = mapChars[mapData[cursorIndex]];
            if(currentMapIndex <= 2) {
                int mapcursor_one_ahead;
                int mapcursor_two_ahead;
                int mapcursor_three_ahead;
                if(currentMapIndex == 1) {
                    mapcursor_one_ahead = mapChars[mapData[cursorIndex + 1]];
                    mapcursor_two_ahead = mapChars[mapData[cursorIndex + 2]];
                    mapcursor_three_ahead = mapChars[mapData[cursorIndex + 3]];
                    cursorIndex += 4;
                } else {
                    mapcursor_one_ahead = mapChars[mapData[cursorIndex + 1]];
                    mapcursor_two_ahead = mapChars[mapData[cursorIndex + 2]];
                    mapcursor_three_ahead = 0;
                    cursorIndex += 3;
                }
                mapTiles[tileX][tileY] = currentMapIndex * 256 * 256 * 256 + mapcursor_one_ahead * 256 * 256 + mapcursor_two_ahead * 256 + mapcursor_three_ahead;
            } else {
                if(currentMapIndex == 3) {
                    mapTiles[tileX][tileY] = mapTiles[tileX - 1][tileY];
                }
                if(currentMapIndex == 4) {
                    mapTiles[tileX][tileY] = mapTiles[tileX][tileY - 1];
                }
                if(currentMapIndex == 5) {
                    mapTiles[tileX][tileY] = mapTiles[tileX - 1][tileY - 1];
                }
                if(currentMapIndex == 6) {
                    mapTiles[tileX][tileY] = mapTiles[tileX - 2][tileY];
                }
                if(currentMapIndex == 7) {
                    mapTiles[tileX][tileY] = mapTiles[tileX][tileY - 2];
                }
                if(currentMapIndex == 8) {
                    mapTiles[tileX][tileY] = mapTiles[tileX - 2][tileY - 2];
                }
                ++cursorIndex;
            }
        }
    }

  }

string tiles[49][25];
void convertCodesToTiles() {
/*
 *
              Tile[][] result = new Tile[49][25];
        for (int y = 0; y < 25; y++) {
                   for (int x = 0; x < 49; x++) {
                       int tileCode = mapTiles[x][y];
                       int isNoSpecial = tileCode / 16777216;
                       int shapeIndex = tileCode / 65536 % 256; // Becomes the SpecialIndex if isNoSpecial==2
                       int foregroundElementIndex = tileCode / 256 % 256;
                       int backgroundElementIndex = tileCode % 256;
                       result[x][y] = new Tile(shapeIndex,foregroundElementIndex,backgroundElementIndex,isNoSpecial);
                   }
               }

    return result;
 */
    for(int y = 0; y < 25; ++y) {
        for(int x = 0; x < 49; ++x) {
            int tileCode = mapTiles[x][y];
            int isNoSpecial = tileCode / 16777216;
            int shapeIndex = tileCode / 65536 % 256; // Becomes the SpecialIndex if isNoSpecial==2
            int foregroundElementIndex = tileCode / 256 % 256;
            int backgroundElementIndex = tileCode % 256;
            tiles[x][y] = "%s"%
        }
    }


  
}
string V; // Version
string A; // Author
string N; // Name
string T; // Tiles
string C; //
string I; //
string R;
string B;

int main(int argc, char *argv[]) {
  if(argc != 2) {
    printf("Usage: <input_file.track>");
  }

  // open input file
  ifstream inputFile(argv[1]);
  if(!inputFile.is_open()) {
    printf("Error: Could not open input file %s\n", argv[1]);
    return 1;
  }

  // read input file to string
  string line;
  while(getline(inputFile, line)) {
    if(line.substr(0, 2) == "V ") {
      V = line.substr(2);
    } else if(line.substr(0, 2) == "A ") {
      A = line.substr(2);
    } else if(line.substr(0, 2) == "N ") {
      N = line.substr(2);
    } else if(line.substr(0, 2) == "T ") {
      T = line.substr(2);
    } else if(line.substr(0, 2) == "C ") {
      C = line.substr(2);
    } else if(line.substr(0, 2) == "I ") {
      I = line.substr(2);
    } else if(line.substr(0, 2) == "R ") {
      R = line.substr(2);
    } else if(line.substr(0, 2) == "B ") {
      B = line.substr(2);
    }
  }
  inputFile.close();
  // printf("Input file: %s\n", inputString.c_str());

  // expand string
  string mapStringDecompressed = decompress(T);
  printf("Decompressed map string: %s\n", mapStringDecompressed.c_str());

  // parse map
  parseMap(mapStringDecompressed);
  // printf("Map parsed\n");
  // for(int y = 0; y < 25; ++y) {
  //   for(int x = 0; x < 49; ++x) {
  //     printf("%d ", mapTiles[x][y]);
  //   }
  //   printf("\n");
  // }

  // convert codes to tiles
  string tiles[49][25];
  tiles = convertCodesToTiles(mapTiles);

  for (int y = 0; y < 25; ++y) {
    for (int x = 0; x < 49; ++x) {
      printf("%s ", tiles[x][y].c_str());
    }
    printf("\n");
  }


  // printf("Tile codes: %s\n", tileCodes[0][0].c_str());



  return 0;
}
