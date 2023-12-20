/* defs.h */
#ifndef BILCO
  #define BILCO
    using namespace std;
    typedef long long int llong; /* change to double if not supported */
    typedef /* component */
      struct componentSt
    {
      struct componentSt *bNext;  /* next node in bucket */
      struct componentSt *bPrev;  /* previous node in bucket */
      struct componentSt *cNext;  /* next node in clear list */
      int *upperBound;            /* upperBound vector of current component */
      int *lowerBound;            /* lowerBound vector of current component */
      llong d;                    /* distance label */
      int gID;                    /* subgraph ID      */
      int startY;                 /* the leftmost horizontal location of current component*/
      int endY;                   /* the rightmost horizontal location of current component*/
      bool activeState;           /* show whether the current component is active or not. May be deleted if don't need it */
    } component;

    typedef /* bucket */
      struct neiInfoSt
    {
      int pairID;
      int gID2;
      int flowDir;
    } neiInfo;

    typedef /* bucket */
      struct bucketSt
    {
      component *firstActive;   /* first node with positive excess */
      component *firstInactive; /* first node with zero excess */
    } bucket;
#endif