/*
/////////////////////////
SNPDuoCCodes.c
Increases the speed and efficiency of SNPDuo by coding it into compiled C code
Created: May 14, 2007
Last Edit: October 16, 2008 - ER
///////////////////////// 
*/
		
#include <stdio.h>

int main (void)
{
   return 0;/* For compiler standards compliance */
}

/*
FastIBS
-- an algorithm do to fast IBS comparisons
*/
void FastIBS (int *size, int *geno1, int *geno2, int *ibs)
{
	unsigned int i=0;
	int currgeno1=0, currgeno2=0;
	
	for (i = 0; i < size[0]; ++i)
	{
		currgeno1 = geno1[i];
		currgeno2 = geno2[i];
		if(currgeno1 != 0 && currgeno2 != 0)
		{
			if(currgeno1 == currgeno2)
			{
				/* == */
				ibs[i] = 2;
			}
			else if (currgeno1 == 1)
			{
				/*AA*/
				if(currgeno2 == 3)
				{
					/*BB*/
					ibs[i] = 0;
				}
				else if (currgeno2 == 2)
				{
					/*AB*/
					ibs[i] = 1;
				}
				
			}
			else if (currgeno1 == 3)
			{
				/*BB*/
				if (currgeno2 == 1)
				{
					/*AA*/
					ibs[i] = 0;
				}
				else if (currgeno2 == 2)
				{
					/*AB*/
					ibs[i] = 1;
				}
				
			}
			else if (currgeno1 == 2)
			{
				/*AB*/
				if(currgeno2 == 1)
				{
					/*AA*/
					ibs[i] = 1;
				}
				else if (currgeno2 == 3)
				{
					/*BB*/
					ibs[i] = 1;
				}
			}
		}
	}
}

/*
FastIBSUncoded
*/

void FastIBSUncoded (int *size, int *geno1, int *geno2, int *ibs)
{
	unsigned int i=0;
	int currgeno1=0, currgeno2=0;
	
	/*
	NC=0
	AA=1
	AC=2
	AG=3
	AT=4
	CC=5
	CG=6
	CT=7
	GG=8
	GT=9
	TT=10
	*/
	
	for (i = 0; i < size[0]; ++i)
	{
		
		currgeno1 = geno1[i];
		currgeno2 = geno2[i];
		
		if (currgeno1 != 0 && currgeno2 != 0)
		{
			
			if(currgeno1 == currgeno2)
			{
				ibs[i] = 2;
			}
			else if (currgeno1 == 1)
			{
				/* AA */
				if (currgeno2 == 2)
				{
					/* AC */
					ibs[i] = 1;
				}
				else if (currgeno2 == 3)
				{
					/* AG */
					ibs[i] = 1;
				}
				else if (currgeno2 == 4)
				{
					/* AT */
					ibs[i] = 1;
				}
				else if (currgeno2 == 5)
				{
					/* CC */
					ibs[i] = 0;
				}
				else if (currgeno2 == 6)
				{
					/* CG */
					ibs[i] = 0;
				}
				else if (currgeno2 == 7)
				{
					/* CT */
					ibs[i] = 0;
				}
				else if (currgeno2 == 8)
				{
					/* GG */
					ibs[i] = 0;
				}
				else if (currgeno2 == 9)
				{
					/* GT */
					ibs[i] = 0;
				}
				else if (currgeno2 == 10)
				{
					/* TT */
					ibs[i] = 0;
				}
			}
			else if (currgeno1 == 2)
			{
				/* AC */
				if (currgeno2 == 1)
				{
					/* AA */
					ibs[i] = 1;
				}
				else if (currgeno2 == 3)
				{
					/* AG */
					ibs[i] = 1;
				}
				else if (currgeno2 == 4)
				{
					/* AT */
					ibs[i] = 1;
				}
				else if (currgeno2 == 5)
				{
					/* CC */
					ibs[i] = 1;
				}
				else if (currgeno2 == 6)
				{
					/* CG */
					ibs[i] = 1;
				}
				else if (currgeno2 == 7)
				{
					/* CT */
					ibs[i] = 1;
				}
				else if (currgeno2 == 8)
				{
					/* GG */
					ibs[i] = 0;
				}
				else if (currgeno2 == 9)
				{
					/* GT */
					ibs[i] = 0;
				}
				else if (currgeno2 == 10)
				{
					/* TT */
					ibs[i] = 0;
				}
			}
			else if (currgeno1 == 3)
			{
				/* AG */
				if (currgeno2 == 1)
				{
					/* AA */
					ibs[i] = 1;
				}
				else if (currgeno2 == 2)
				{
					/* AC */
					ibs[i] = 1;
				}
				else if (currgeno2 == 4)
				{
					/* AT */
					ibs[i] = 1;
				}
				else if (currgeno2 == 5)
				{
					/* CC */
					ibs[i] = 0;
				}
				else if (currgeno2 == 6)
				{
					/* CG */
					ibs[i] = 1;
				}
				else if (currgeno2 == 7)
				{
					/* CT */
					ibs[i] = 0;
				}
				else if (currgeno2 == 8)
				{
					/* GG */
					ibs[i] = 1;
				}
				else if (currgeno2 == 9)
				{
					/* GT */
					ibs[i] = 1;
				}
				else if (currgeno2 == 10)
				{
					/* TT */
					ibs[i] = 0;
				}
			}
			else if (currgeno1 == 4)
			{
				/* AT */
				if (currgeno2 == 1)
				{
					/* AA */
					ibs[i] = 1;
				}
				else if (currgeno2 == 2)
				{
					/* AC */
					ibs[i] = 1;
				}
				else if (currgeno2 == 3)
				{
					/* AG */
					ibs[i] = 1;
				}
				else if (currgeno2 == 5)
				{
					/* CC */
					ibs[i] = 0;
				}
				else if (currgeno2 == 6)
				{
					/* CG */
					ibs[i] = 0;
				}
				else if (currgeno2 == 7)
				{
					/* CT */
					ibs[i] = 1;
				}
				else if (currgeno2 == 8)
				{
					/* GG */
					ibs[i] = 0;
				}
				else if (currgeno2 == 9)
				{
					/* GT */
					ibs[i] = 1;
				}
				else if (currgeno2 == 10)
				{
					/* TT */
					ibs[i] = 1;
				}
			}
			else if (currgeno1 == 5)
			{
				/* CC */
				if (currgeno2 == 1)
				{
					/* AA */
					ibs[i] = 0;
				}
				else if (currgeno2 == 2)
				{
					/* AC */
					ibs[i] = 1;
				}
				else if (currgeno2 == 3)
				{
					/* AG */
					ibs[i] = 0;
				}
				else if (currgeno2 == 4)
				{
					/* AT */
					ibs[i] = 0;
				}
				else if (currgeno2 == 6)
				{
					/* CG */
					ibs[i] = 1;
				}
				else if (currgeno2 == 7)
				{
					/* CT */
					ibs[i] = 1;
				}
				else if (currgeno2 == 8)
				{
					/* GG */
					ibs[i] = 0;
				}
				else if (currgeno2 == 9)
				{
					/* GT */
					ibs[i] = 0;
				}
				else if (currgeno2 == 10)
				{
					/* TT */
					ibs[i] = 0;
				}
			}
			else if (currgeno1 == 6)
			{
				/* CG */
				if (currgeno2 == 1)
				{
					/* AA */
					ibs[i] = 0;
				}
				else if (currgeno2 == 2)
				{
					/* AC */
					ibs[i] = 0;
				}
				else if (currgeno2 == 3)
				{
					/* AG */
					ibs[i] = 1;
				}
				else if (currgeno2 == 4)
				{
					/* AT */
					ibs[i] = 0;
				}
				else if (currgeno2 == 5)
				{
					/* CC */
					ibs[i] = 1;
				}
				else if (currgeno2 == 7)
				{
					/* CT */
					ibs[i] = 1;
				}
				else if (currgeno2 == 8)
				{
					/* GG */
					ibs[i] = 1;
				}
				else if (currgeno2 == 9)
				{
					/* GT */
					ibs[i] = 1;
				}
				else if (currgeno2 == 10)
				{
					/* TT */
					ibs[i] = 0;
				}
			}
			else if (currgeno1 == 7)
			{
				/* CT */
				if (currgeno2 == 1)
				{
					/* AA */
					ibs[i] = 0;
				}
				else if (currgeno2 == 2)
				{
					/* AC */
					ibs[i] = 1;
				}
				else if (currgeno2 == 3)
				{
					/* AG */
					ibs[i] = 0;
				}
				else if (currgeno2 == 4)
				{
					/* AT */
					ibs[i] = 1;
				}
				else if (currgeno2 == 5)
				{
					/* CC */
					ibs[i] = 1;
				}
				else if (currgeno2 == 6)
				{
					/* CG */
					ibs[i] = 1;
				}
				else if (currgeno2 == 8)
				{
					/* GG */
					ibs[i] = 0;
				}
				else if (currgeno2 == 9)
				{
					/* GT */
					ibs[i] = 1;
				}
				else if (currgeno2 == 10)
				{
					/* TT */
					ibs[i] = 1;
				}
			}
			else if (currgeno1 == 8)
			{
				/* GG */
				if (currgeno2 == 1)
				{
					/* AA */
					ibs[i] = 0;
				}
				else if (currgeno2 == 2)
				{
					/* AC */
					ibs[i] = 0;
				}
				else if (currgeno2 == 3)
				{
					/* AG */
					ibs[i] = 1;
				}
				else if (currgeno2 == 4)
				{
					/* AT */
					ibs[i] = 0;
				}
				else if (currgeno2 == 5)
				{
					/* CC */
					ibs[i] = 0;
				}
				else if (currgeno2 == 6)
				{
					/* CG */
					ibs[i] = 1;
				}
				else if (currgeno2 == 7)
				{
					/* CT */
					ibs[i] = 0;
				}
				else if (currgeno2 == 9)
				{
					/* GT */
					ibs[i] = 1;
				}
				else if (currgeno2 == 10)
				{
					/* TT */
					ibs[i] = 0;
				}
			}
			else if (currgeno1 == 9)
			{
				/* GT */
				if (currgeno2 == 1)
				{
					/* AA */
					ibs[i] = 0;
				}
				else if (currgeno2 == 2)
				{
					/* AC */
					ibs[i] = 0;
				}
				else if (currgeno2 == 3)
				{
					/* AG */
					ibs[i] = 1;
				}
				else if (currgeno2 == 4)
				{
					/* AT */
					ibs[i] = 1;
				} 
				else if (currgeno2 == 5)
				{
					/* CC */
					ibs[i] = 0;
				}
				else if (currgeno2 == 6)
				{
					/* CG */
					ibs[i] = 1;
				}
				else if (currgeno2 == 7)
				{
					/* CT */
					ibs[i] = 1;
				}
				else if (currgeno2 == 8)
				{
					/* GG */
					ibs[i] = 1;
				}
				else if (currgeno2 == 10)
				{
					/* TT */
					ibs[i] = 1;
				}
			}
			else if (currgeno1 == 10)
			{
				/* TT */
				if (currgeno2 == 1)
				{
					/* AA */
					ibs[i] = 0;
				}
				else if (currgeno2 == 2)
				{
					/* AC */
					ibs[i] = 0;
				}
				else if (currgeno2 == 3)
				{
					/* AG */
					ibs[i] = 0;
				}
				else if (currgeno2 == 4)
				{
					/* AT */
					ibs[i] = 1;
				}
				else if (currgeno2 == 5)
				{
					/* CC */
					ibs[i] = 0;
				}
				else if (currgeno2 == 6)
				{
					/* CG */
					ibs[i] = 0;
				}
				else if (currgeno2 == 7)
				{
					/* CT */
					ibs[i] = 1;
				}
				else if (currgeno2 == 8)
				{
					/* GG */
					ibs[i] = 0;
				}
				else if (currgeno2 == 9)
				{
					/* GT */
					ibs[i] = 1;
				} 
			}
		}
	}
}

/*
CountGenotypes
-- an algorithm to summarize genotype counts quickly
*/

void CountGenotypes (int *size, int *geno, int *NC, int *AA, int *AB, int *BB)
{	
	/*
	AA = 1
	AB = 2
	BB = 3
	NC = 0
	*/
	
	unsigned int i=0;
	
	for (i = 0; i < size[0]; ++i)
	{
		if(geno[i] == 1)
		{
			++AA[0];
		}
		else if (geno[i] == 3)
		{
			++BB[0];
		}
		else if (geno[i] == 2)
		{
			++AB[0];
		}
		else if (geno[i] == 0)
		{
			++NC[0];
		}
	}
}

/*
SummarizeIBS
-- an algorithm to count the IBS states in a vector quickly
*/
void SummarizeIBS (int *size, int *ibsvector, int *ibs0count, int *ibs1count, int *ibs2count)
{
	unsigned int i=0;
	for (i = 0; i < size[0]; ++i)
	{
		if(ibsvector[i] == 2)
		{
			++ibs2count[0];
		}
		else if (ibsvector[i] == 1)
		{
			++ibs1count[0];
		}
		else if (ibsvector[i] == 0)
		{
			++ibs0count[0];
		}
	}
}

/*
CountUncodedGenotypes
-- an algorithm to summarize counts of biallelic genotypes in uncoded (non-AA/AB/BB data)
*/
void CountUncodedGenotypes (int *size, int *geno, int *NC, int *AA, int *AC, int *AG, int *AT, int *CC, int *CG, int *CT, int *GG, int *GT, int *TT)
{
	/*
	NC=0
	AA=1
	AC=2
	AG=3
	AT=4
	CC=5
	CG=6
	CT=7
	GG=8
	GT=9
	TT=10
	*/
	
	/* Set everything to 0 just to be sure*/
	NC[0] = 0;
	AA[0] = 0;
	AC[0] = 0;
	AG[0] = 0;
	AT[0] = 0;
	CC[0] = 0;
	CG[0] = 0;
	CT[0] = 0;
	GG[0] = 0;
	GT[0] = 0;
	TT[0] = 0;
	
	unsigned int i=0;
	int currGeno=0;
	
	for (i = 0; i < size[0]; ++i)
	{
		currGeno = geno[i];
		if(currGeno == 1)
		{
			++AA[0];
		}
		else if
		(currGeno == 2) {
			++AC[0];
		}
		else if
		(currGeno == 3) {
			++AG[0];
		}
		else if (currGeno == 4)
		{
			++AT[0];
		}
		else if (currGeno == 5)
		{
			++CC[0];
		}
		else if (currGeno == 6)
		{
			++CG[0];
		}
		else if (currGeno == 7)
		{
			++CT[0];
		}
		else if (currGeno == 8)
		{
			++GG[0];
		}
		else if (currGeno == 9)
		{
			++GT[0];
		}
		else if (currGeno == 10)
		{
			++TT[0];
		}
		else if (currGeno == 0)
		{
			++NC[0];
		}
	}
}

/*
CountIBSFromGenotypes
-- an algorithm to count IBS states only
*/

void CountIBSFromGenotypes (int *size, int *geno1, int *geno2, int *ibs0, int *ibs1, int *ibs2)
{
	
	/*
	AA=1
	AB=2
	BB=3
	NC=0
	*/
	
	unsigned int i=0;
	int currGeno1=0, currGeno2=0;
	
	for(i = 0; i < size[0]; ++i)
	{
		currGeno1 = geno1[i];
		currGeno2 = geno2[i];
		
		if(currGeno1 != 0 && currGeno2 != 0)
		{
			if (currGeno1 == currGeno2)
			{
				/* == */
				++ibs2[0];
			}
			else if (currGeno1 == 1)
			{
				/* AA */
				if (currGeno2 == 3)
				{
					/* BB */
					++ibs0[0];
				}
				else if(currGeno2 == 2)
				{
					/* AB */
					++ibs1[0];
				}
			}
			else if (currGeno1 == 3)
			{
				/* BB */
				if(currGeno2 == 1)
				{
					/* AA */
					++ibs0[0];
				}
				else if (currGeno2 == 2)
				{
					/* AB */
					++ibs1[0];
				}
			}
			else if (currGeno1 == 2)
			{
				/* AB */
				if(currGeno2 == 1)
				{
					/* AA */
					++ibs1[0];
				}
				else if (currGeno2 == 3)
				{
					/* BB */
					++ibs1[0];
				}
			}
		}
	}
}

/*
void SNPScore
A C script for scoring SNP similarity in C for speed
Based on original R Script
Created: 
Last Edit: October 05, 2007 - ER
*/

void SNPScore (int *size, int *geno1, int *geno2, int *score, int *ibs2count, int *ibs1count, int *ibs0count, int *ind1AA, int *ind1AB, int *ind1BB, int *ind1NC, int *ind2AA, int *ind2AB, int *ind2BB, int *ind2NC)
{
	/* IBS Subroutine*/
	FastIBS(size, geno1, geno2, score);
	
	/* Count genotypes */
	/* Individual 1 */
	CountGenotypes(size, geno1, ind1NC, ind1AA, ind1AB, ind1BB);
	/* Individual 2 */
	CountGenotypes(size, geno2, ind2NC, ind2AA, ind2AB, ind2BB);
	
	/* Summarize IBS counts */
	SummarizeIBS(size, score, ibs0count, ibs1count, ibs2count);
}
