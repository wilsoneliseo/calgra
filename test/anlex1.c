/* Descripcion:
      Realiza el analisis lexico de un termino de una funcion
      polinomica. Una cadena correcta debe iniciar con '+' o '-'
      seguido de cero, uno o dos digitos. Luego puede venir o no una
      'x' o bien 'x^' seguido por '2' o '3' o '4' la expresion
      regular es la siguiente:
          ER=('+'|'-')(<d>?<d>)?[x^<expo>|x]?
      donde: <d>=0|1|2|3|4|5|6|7|8|9 y <expo>=2|3|4

      Esta ER para algunos comandos de Unix (funciona en Emacs) puede
      escribirse como:
          ER=\(\+\|-\)\([[:digit:]]?[[:digit:]]\)?\(x^[234]\|x\)?
      
      Estos son algunos ejemplos de cadenas lexicamente correctas para
      este lenguaje:
              +2x +1 -99x +29 -9x^3 +55x^2 +x +29

      Desafortunadamente no se previo que la ER aceptaba cadenas como:
      '+' ó '-'

      Si la cadena es exitosa el programa muestra el coeficiente y el
      exponente del termino.

      Si la cadena es incorrecta el programa muestra la fila y columna
      y el caracter defectuoso acompañado de un mensaje pertinente.

      Para obtener la tabla de transiciones se realizó manualmente
      utilizando el método del árbol.

   Compilacion:
       Se utilizó el compilador de GNU gcc en MS-Windows de la
       siguiente forma:

           - Compilacion:
                > gcc anlex1.c -o anlex1.exe

	   - Ejecucion
	        > anlex1.exe

       Después de compilar la primera vez creará un archivo llamado
       fuente.txt, el cual contendrá una entrada de ejemplo. Para
       variar la entrada, modificar ese archivo y ejecutar así:

                > anlex1.exe fuente.txt

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
    {ERROR, ERROR,   E,     D,   ERROR, ERROR, ACEPTAR }, /*   2 C   */
    {ERROR, ERROR, ERROR, ERROR,   F,   ERROR, ACEPTAR }, /*   3 D   */
    {ERROR, ERROR, ERROR,   D,   ERROR, ERROR, ACEPTAR }, /*   4 E   */
    {ERROR, ERROR, ERROR, ERROR, ERROR,   D,   ERROR   }  /*   5 F   */
                                                          /*    ^    */
                                                          /*    |    */
                                                          /*  Estado */
  };
 
/*prototipos*/
void CrearArchivoFuente(void);
void RutinaError(char c, int col, int fil, char * msj);
 
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
	  columna=1;
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
	  if(Entrada==SIGNO_MAS)
	    {
	      /* Este if significa que la entrada entrerior fue
		 un caracter '+'. Por lo tanto se inicia la
		 cadena con un '+' y a continuacion se coloca el
		 digito actual */
	      coeficiente[0]='+';
	      coeficiente[1]=c;
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
	      if(Entrada==SIGNO_MAS)
		{
		  /* Este if significa que la entrada entrerior fue
		     un caracter '+'. Por lo tanto se inicia la
		     cadena con un '+' y a continuacion se coloca el
		     digito actual */
		  coeficiente[0]='+';
		  coeficiente[1]=c;
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
	      
	      Entrada=DIGITO;
	    }	    
	  break;
	case ';':
          Entrada=FDC;
          break;
	case '+':
	  Entrada=SIGNO_MAS;
	  break;
	case '-':
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
  printf("Coeficiente:%s  Exponente: %c\n",coeficiente,exponente);
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
  
  fprintf(fp,"\n\n  -77   x^4;");
  /* fprintf(fp,"\n  -x;"); */
  /* fprintf(fp,"\n  +4;"); */
  fclose(fp);
}
 
//Dar el caracter, fila y columna del error léxico
void RutinaError(char c, int col, int fil, char * msj)
{
  fprintf(stderr,"[ErrorLexico] %s\nfila:%d columna:%d caracter:`%c`\n",\
	  msj,fil,col-1,c);
  exit(EXIT_FAILURE);
}
