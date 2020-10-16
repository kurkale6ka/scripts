#include <stdio.h>
#include <stdlib.h>

int main (int argc, char* argv[])
{
   enum Number { One = 1, Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten, Eleven, Twelve };
   enum Number num = One;

   short cols;

   if (argc > 1)
      cols = atoi(argv[1]);
   else
      cols = 4;

   for (short i = 1; i <= Twelve; i+=cols)
   {
      // Headers
      if (i > 1) printf("\n");

      for (short k = 0; k <= cols-1; k++)
         printf("%-13d   ", num++);

      printf("\n");
      for (int i = 1; i <= 16*cols-3 ; i++)
         printf("-");
      printf("\n");

      for (short j = 0; j <= Twelve; j++)
      {
         for (short k = 0; k <= cols-1; k++)
            printf("%-2hd x %-2hd = %3hd   ", (short)(i+k), j, (short)((i+k)*j));

         printf("\n");
      }
   }
   return 0;
}
