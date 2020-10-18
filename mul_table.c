#include <stdio.h>
#include <stdlib.h>

int main (int argc, char* argv[])
{
   enum Number { One = 1, Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten, Eleven, Twelve };
   enum Number num = One;

   short cols;

   if (argc > 1)
   {
      cols = atoi(argv[1]);
      if (cols < 1 || cols == 5 || (cols > 6 && cols < 12) || cols > 12)
      {
         printf("The possible columns are the divisors of 12: 1,2,3,4,6,12. "
               "Try again!\n");
         return 1;
      }
   }
   else
      cols = 4;

   // sets of cols columns
   for (short i = 1; i <= Twelve; i+=cols)
   {
      // -------
      if (i > 1)
      {
         for (short i = 1; i <= 16*cols-3 ; i++) printf("─");
         printf("\n");
      }

      // Headers
      for (short k = 0; k <= cols-1; k++)
      {
         switch(num++)
         {
            case    One: printf("     ONE        "); break;
            case    Two: printf("     TWO        "); break;
            case  Three: printf("    THREE       "); break;
            case   Four: printf("    FOUR        "); break;
            case   Five: printf("    FIVE        "); break;
            case    Six: printf("     SIX        "); break;
            case  Seven: printf("    SEVEN       "); break;
            case  Eight: printf("    EIGHT       "); break;
            case   Nine: printf("    NINE        "); break;
            case    Ten: printf("     TEN        "); break;
            case Eleven: printf("   ELEVEN       "); break;
            case Twelve: printf("   TWELVE");        break;
         }
      }
      printf("\n");

      for (short j = 0; j <= Twelve; j++)
      {
         for (short k = 0; k <= cols-1; k++)
         {
            printf("%-2hd x %2hd = %3hd", j, (short)(i+k), (short)((i+k)*j));
            printf("%s", k < cols-1 ?  " │ " : "");
         }
         printf("\n");
      }
   }

   return 0;
}
