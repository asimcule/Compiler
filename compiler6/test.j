
global int x;
global int ynotused;
global int arr[100];

function makePattern(string s1, string s2, int val)
{
   int y;
   call printStr("Arg val is: ");
   call printInt(val);
   call printStr("\nPrinting a pattern\n");
   while (x != 0) do {
      y = 0;
      while (y < x) do {
         call printStr("*");
         y = y + 1;
      }
      call printStr("\n");
      x = x - 1;
   }
}

function arrayFun(int size, int startVal)
{
   int i;
   int sum;
   i = 0; 
   while (i < size) do {
      arr[i] = startVal;
      startVal = startVal + 1;
      i = i + 1;
   }
   i = 0; 
   while (i < size) do {
      call printStr("arr[");
      call printInt(i);
      call printStr("] = ");
      call printInt(arr[i]);
      call printStr("\n");
      i = i + 1;
   }
   i = 0; 
   sum = 0;
   while (i < size) do {
      sum = sum + arr[i];
      i = i + 1;
   }
   call printStr("array sum = ");
   call printInt(sum);
   call printStr("\n");
}

program {
   call printStr("Enter value for x: ");
   call readInt();
   x = returnvalue;
   if (x > 100) then {
      call printStr("x is over 100!\n");
   } else {
      call printStr("x is 100 or less!\n");
   }
   call makePattern("hello", "goodbye", 42);
   call printStr("Enter starting array value: ");
   call readInt();
   x = returnvalue;
   call arrayFun(20,x);
   call printStr("Program done.\n");
}
