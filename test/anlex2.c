/* Descripcion:
      Realiza lo mismo que anlex.c pero se modifico la tabla de
      transiciones de tal modo que ahora reconoce expresiones
      polinomicas, de maximo grado 4, y varios terminos. 

      La modificacion en la tabla de transiciones consiste en regresar
      hacia el estado B cuando se esta en los estados C, D, o E y
      tiene como entrada ya sea '+' o '-'. Esto aunado con la funcion
      terminoCompleto() para detectar cuando se completo un termino,
      hacen mostrar el coeficiente y exponente cada que se completa un
      termino. 

      Desafortunadamente no se previo que la ER aceptaba cadenas como:
      '+' ó '-'

   Compilacion:
       Se utilizó el compilador de GNU gcc en MS-Windows de la
       siguiente forma:

           - Compilacion:
                > gcc anlex2.c -o anlex2.exe

	   - Ejecucion
	        > anlex2.exe

       Después de compilar la primera vez creará un archivo llamado
       fuente.txt, el cual contendrá una entrada de ejemplo. Para
       variar la entrada, modificar ese archivo y ejecutar así:

                > anlex2.exe fuente.txt

   Autor:
        Wilson S. Tubin
	wilsoneliseogt@gmail.com
      */
#include<stdio.h>
#include<stdlib.h>

FILE *fp;
char c;    /* guardar caracter */
int columna=0;
int fila=1;
char *NombreArchivo="fuente.txt";

enum {SIGNO_MAS=0, SIGNO_MENOS, DIGITO, X, POW, EXPONENTE,FDC}; /*columnas TB */
enum {A,B,C,D,E,F};						/* filas TB */
enum {ERROR=20,ACEPTAR};					/* constantes */
int Entrada;  /* guarda algun valor de las columnas de TB */
int Estado;   /* guarda algun valor de las filas de TB */

char exponente;
char coeficiente[4];		/* ej: +34\0 */


int TablaDeTransiciones[6][7]=	/* tabla de transiciones= TB */
  /*   0      1      2      3      4      5      6      | <-Entrada  */
  /*   +      -      d      x      ^   EXPONE   FDC     |            */
  { {  B,     B,   ERROR, ERROR, ERROR, ERROR, ERROR   }, /*   0 A   */
    {ERROR, ERROR,   C,     D,   ERROR, ERROR, ACEPTAR }, /*   1 B   */
    {  B,     B,     E,     D,   ERROR, ERROR, ACEPTAR }, /*   2 C   */
    {  B,     B,   ERROR, ERROR,   F,   ERROR, ACEPTAR }, /*   3 D   */
    {  B,     B,   ERROR,   D,   ERROR, ERROR, ACEPTAR }, /*   4 E   */
    {ERROR, ERROR, ERROR, ERROR, ERROR,   D,   ERROR   }  /*   5 F   */
                                                          /*    ^    */
                                                          /*    |    */
                                                          /*  Estado */
  };
 
/*prototipos*/
void CrearArchivoFuente(void);
void RutinaError(char c, int col, int fil, char * msj);
void manejarCoeficiente(void);
void terminoCompleto(void);
 
void main(int numArgumentos, char *ArregloDeArgumentos[])
{
  if(numArgumentos==2)
    NombreArchivo=ArregloDeArgumentos[1];
  else
    {
      CrearArchivoFuente();
    }
 
  if((fp=fopen(NombreArchivo,"rt"))==NULL)
    {
      fprintf(stderr,"Error al abrir el archivo\n");
      exit(EXIT_FAILURE);
    }
  
  Estado=0;
  do
    {
      c=getc(fp);
       
      if(c=='\n')
	{
	  columna=0;
	  fila+=1;
	  continue;
	}
      else if(c==' ')		/* ignorar espacios en blanco */
	{
	  columna++;
	  continue;
	}
      else
	columna++;
      
      switch (c)
	{
	case '0':
	case '1':
	case '5':
	case '6':
	case '7':
	case '8':
	case '9':
	  manejarCoeficiente();
          Entrada=DIGITO;
          break;
	case '2':
	case '3':
	case '4':
	  if(Entrada==POW)	/* si la entrada anterior fue el char '^' */
	    {
	      exponente=c;
	      Entrada=EXPONENTE;
	    }
	  else
	    {
	      manejarCoeficiente();
	      Entrada=DIGITO;
	    }	    
	  break;
	case ';':
          Entrada=FDC;
          break;
	case '+':
	  terminoCompleto();
	  Entrada=SIGNO_MAS;
	  break;
	case '-':
	  terminoCompleto();
	  Entrada=SIGNO_MENOS;
	  break;
	case 'x':
	      if(Entrada==SIGNO_MAS)
	      	{
	      	  /* Este if significa que la entrada entrerior fue
	      	     un caracter '+'. Por lo que el coeficiente es +1 */
	      	  coeficiente[0]='1';
	      	  coeficiente[1]='\0';
		  exponente='1';
	      	}
	        if(Entrada==SIGNO_MENOS)
	      	{
	      	  /* Este else significa que la entrada entrerior fue
	      	     un caracter '-'. Por lo que coeficiente es -1 */
	      	  coeficiente[0]='-';
	      	  coeficiente[1]='1';
	      	  coeficiente[2]='\0';
		  exponente='1';
	      	}
		if(Entrada==DIGITO)
		  {
		    exponente='1';
		  }
	      
	  Entrada=X;
	  break;
	case '^':
	  Entrada=POW;
	  break;
	default:
	  RutinaError(c,columna,fila,"Caracter no reconocido");
	  break;
	}//fin del switch
      
      Estado=TablaDeTransiciones[Estado][Entrada];
      if(Estado==ERROR)
	RutinaError(c,columna,fila,"Caracter no debe ir en esta posicion");
      
    }while(Estado!=ACEPTAR);
  
  printf("El termino es lexicamente correcto\n");
  printf("FIN:Coeficiente:%s  Exponente: %c\n",coeficiente,exponente);
  fclose(fp);
}

//para crear una archivo fuente de ejemplo
void CrearArchivoFuente(void)
{
  if((fp=fopen(NombreArchivo,"wt"))==NULL)    
    {
      fprintf(stderr,"No se puede abrir archivo para escribir fuente");
      exit(EXIT_FAILURE);      
    }
  
  fprintf(fp,"\n\n  +1 - 99 x+29 +47 x^2+ 5 5x^ 2;");
  /* fprintf(fp,"\n  -x;"); */
  /* fprintf(fp,"\n  +4;"); */
  fclose(fp);
}
 
//Dar el caracter, fila y columna del error léxico
void RutinaError(char c, int col, int fil, char * msj)
{
  fprintf(stderr,"[ErrorLexico] %s\nfila:%d columna:%d caracter:`%c`\n",\
	  msj,fil,col,c);
  exit(EXIT_FAILURE);
}

void manejarCoeficiente(void)
{
  if(Entrada==SIGNO_MAS)
    {
      /* Este if significa que la entrada entrerior fue
	 un caracter '+'. Por lo tanto se inicia la
	 cadena con un '+' y a continuacion se coloca el
	 digito actual */
      coeficiente[0]='+';
      coeficiente[1]=c;
      coeficiente[2]='\0';
      exponente='0';		  
    }	    
  else if(Entrada==SIGNO_MENOS)
    {
      /* Este else significa que la entrada entrerior fue
	 un caracter '-'. Por lo tanto se inicia la
	 cadena con un '-' y a continuacion se coloca el
	 digito actual */
      coeficiente[0]='-';
      coeficiente[1]=c;
      coeficiente[2]='\0';
      exponente='0';
    }
  else		
    {
      /* Este else significa que la entrada enterior fue
	 digito, por lo tanto se guarda el digito actual
	 y se termina la cadena con \0 */
      coeficiente[2]=c;
      coeficiente[3]='\0';
      exponente='0';
    }	      
}

void terminoCompleto(void)
{
  if(Estado==C)
    printf("Coeficiente:%s  Exponente: %c\n",coeficiente,exponente);

  if(Estado==E)
     printf("Coeficiente:%s  Exponente: %c\n",coeficiente,exponente);

  if(Estado==D)
     printf("Coeficiente:%s  Exponente: %c\n",coeficiente,exponente);
  
}
