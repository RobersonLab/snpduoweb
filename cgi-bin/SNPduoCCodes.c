/*
SNPDuoCCodes.c
Increases the speed and efficiency of SNPDuo by coding it into compiled C code
Created: May 14, 2007
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
