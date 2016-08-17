lass MatrixStream{
  int xOffSet;
  int yDump;
  int ch=0;
  MatrixStream(int a, int b){
    xOffSet=a;
    yDump=b;
  }
  
  void grow(){
    if(ch<yDump+20){
      ch+=13;
    }
  }
  
  void drw(){
    for(int i=0;i<ch;i+=13){
      char k = Character.toChars(Math.round(random(33,122)))[0];
      text(k,xOffSet,i);
    }
  }
}
int num=63;
MatrixStream ok[]=new MatrixStream[num];
void setup()  { 
  size(800,800);
  background(0);
  smooth();
  fill(63,208,12);
  for(int i=0;i<num;i++){
    int offset = (int)random(0,800);
    int dump = (int)random(0,800);
    ok[i]=new MatrixStream(offset,dump);
  }
}    

void draw()  {    
  for(int i=0;i<num;i++)
    ok[i].grow();
  background(0);
  for(int i=0;i<num;i++)
    ok[i].drw();
  delay(27);
}  

void delay(int delay)
{
  int time = millis();
  while(millis() - time <= delay);
}