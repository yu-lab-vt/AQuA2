/* MyMEXFunction 
Maximum flow - component highest label push-relabel algorithm 
Specific for GTW problem 

INPUT：
ref: N x T1 matrix. Each row is one reference curve. 
tst: N x T2 matrix. Each row is one test curve.
subgraphNeiRelations: nPair x 3 matrix. Each row is: [gID1,gID2,cap] represent gID1 and gID2 are neighbor. cap is smoothness.
*/

/* setting */
// #define DEBUG
// #define CAP_TYPE_LONG

#ifndef DEBUG
    #include "mex.h"
    #define MATLAB_ASSERT(expr,msg) if (!(expr)) { mexErrMsgTxt(msg);}
#else
    #include <iostream>
    #include <assert.h>
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <cstring>
#include <unordered_set>
#include <unordered_map>
#include "types_BILCO.h"  /* type definitions */
#include <float.h>

typedef float capType; /* change to double if not supported */
#define CAP_MAX FLT_MAX
#define RESOLUTION 0.00001

/* Graph variables */
capType *neiCap;                    /* capacity between neighbor graph */
capType **distMatrix;                /* 3D->1D array of distance matrix (N X T1 X T2): gID, y, x */
int *Gij;                           /* 2D array of subgraph linkage relationship (nPair X 2): pairID, 2  */
component ***comLabels;              /* 4D->1D array of component address (N X T1-1 X T2-1 X 2): gID, y, x, z  */
capType **inOutFlow;                 /* 4D->1D array of in-out flow (N X T1-1 X T2-1 X 2): gID, y, x, z. Negative: in. Postive: out */
capType **flow;                      /* 4D->1D array of flows (nPair X T1-1 X T2-1 X 2). pairID, y, x, z */
int *initialCut;                    /* initial cut for two-stage method. (N * T2-1): gID, y */
neiInfo *gRelations;                /* 1D array to record relationship between graph. (N X maxNeiNum) */
int* addNeiCnt;                     /* 1D array to count how many neighbors added for one subgraph. (N). gID */
int maxNeiNum = 16;                 /* max number of neighbor for each pixels */
int winSize = 100000;

/* global variables */
bucket *buckets;                    /* array of buckets */
llong dMax;                        /* maximum label */
llong ddMax;                       /* max reached label */
llong aMax;                        /* maximum actie node label */
llong aMin;                        /* minimum active node label */
component *sentinel;                /* pointer of sentinel */
int N;                              /* number of subgraph */
int T1;                             /* number of ref curve length */
int T2;                             /* number of tst curve length */
int tempT1;                         /* T1-1  */
int nPair;                          /* number of neighbor pair */
int **lowGraphBound;                /* lowerBound of Graph */
int **upGraphBound;                 /* upperBound of Graph */
llong **accumNumNode;                 /* accumulative number of node - for find node position*/
llong **accumEdgeNum;                /* accumulative number of edges - for find edge position*/
int colNode;
int colNodeNum;

/* temporal variables using multiple times */
llong totalNode;                   /* number of total node */
int *tempCut;                       /* temporal Cut variable. (T1-1), y */
capType *minCutColumn;              /* 1D array to record temporal min Cut variable. (T2 X 2) */
capType *pushedFlow;                /* 1D array to record temporal pushed flow. (T2 -1 X 2) */
capType **Dmatrix;                  /* 2D array for dynamic programming: shortest path from bottom-left. (T1 X T2). y, x */
capType **Rmatrix;                  /* 2D array for dynamic programming: shortest path from top-right. (T1 X T2). y, x */
int **dirs;                         /* 2D array for dynamic programming: direction matrix. 1: up; 2: inclined; 3: right. (T1 X T2). y, x */
int **revDirs;                      /* 2D array for dynamic programming: direction matrix. 1: up; 2: inclined; 3: right. (T1 X T2). y, x */
llong bucketSize = 128;            /* For saving memory */
capType Cx;                         /* vertical cost (y,x) (y, x+1) */
capType Cy;                         /* horizontal cost (y,x) (y+1, x) */
capType Cxy;                        /* inclined cost (y,x) (y+1, x+1) */
capType minV;                       /* temporal min value */
capType *sourceModify;              /* 3D array->1D array. The modified edge weight due to linkage with source. (T1-1 X T2 X 2). y, x, z */
capType *sinkModify;                /* 3D array->1D array. The modified edge weight due to linkage with sink. (T1-1 X T2 X 2). y, x, z */
capType *totalModify;               /* 3D array->1D array. The summation of modified edge weight. (T1-1 X T2 X 2). y, x, z */

/* container */
component *clearHead;               /* head in clear stack: the stack record the components which are no use except their labels */
component *queueHead;               /* head in queue list: record the components should to be merged. */

/* for saving time */
bool sameComp;
bool noMerge;

/* avoid dead loop due to float data type*/
bool statusChanged;
llong preLabel;     

/* For debug */
llong deBugCnt;

/* Container */
unordered_map<component *,unordered_set<component *>> withinLinkage;    /* For global relabel. Only use in global relabel  */
unordered_map<component *,unordered_set<component *>> neiLinkage;       /* For global relabel. Only use in global relabel */
unordered_set<component *> candidateSet;                                /* For merging */

/* function macros */
#define AisNonLargerB(a,b) !(a-b>b*RESOLUTION)

/* ------------ DTW macros -------------- */
/* positive direction */
#define trackBack(){                        \
    int x = endX;                           \
    int y = endY;                           \
    while (y>startY)                        \
    {                                       \
        switch (dirs[y][x]){                \
        case 1:                             \
            --x;                            \
            break;                          \
        case 2:                             \
            tempCut[--y] = (x<<1) - 1;      \
            --x;                            \
            break;                          \
        case 3:                             \
            tempCut[--y] = x<<1;            \
            break;                          \
        default:                            \
            break;                          \
        }                                   \
    }                                       \
}
/* reverse direction */
#define revTrackBack(){                     \
    int x = startX;                         \
    int y = startY;                         \
    while (y<endY)                          \
    {                                       \
        switch (revDirs[y][x]){             \
        case 1:                             \
            ++x;                            \
            break;                          \
        case 2:                             \
            tempCut[y] = (x<<1) + 1;        \
            ++x;                            \
            ++y;                            \
            break;                          \
        case 3:                             \
            tempCut[y] = x<<1;              \
            ++y;                            \
            break;                          \
        default:                            \
            break;                          \
        }                                   \
    }                                       \
}

/* ------ basic operation macros --------- */
#define max(a, b) (a > b ? a : b)
#define min(a, b) (a < b ? a : b)
#define ceil(a) ((a+1)>>1)
#define floor(a) (a>>1)
#define abs(a) (a > 0? a : -a)
#define isInteger(a) (a-(int)a<1e-6)

#define copyVector(tempCut,target,y0,y1){   \
    memcpy(target+y0,tempCut+y0,(y1-y0)*4); \
}

#define clearComp(curComp){                 \
    delete[] curComp->lowerBound;           \
    delete[] curComp->upperBound;           \
}     

/* ---------- bucket macros ------------ */
component *com_next, *com_prev;
/* initialize bucket list */
#define initBucket(l){              \
    l->firstActive = sentinel;      \
    l->firstInactive = sentinel;    \
}


/* maintain bucket, only for relabel operation */
/* only for highest-label criteria */
#define bucketMaintain(newLabel){                       \
    if (newLabel > aMax)                                \
        aMax = newLabel;                                \
    if (dMax < aMax){                                   \
        dMax = aMax;                                    \
        if(newLabel>=bucketSize){                       \
            llong newSize = bucketSize<<1;               \
            while(newSize<=newLabel)                    \
                newSize = newSize<<1;                   \
            bucket* newBuckets = new bucket[newSize];   \
            memcpy(newBuckets,buckets,bucketSize*16);   \
            delete[] buckets;                           \
            buckets = newBuckets;                       \
            bucketSize = newSize;                       \
        }                                               \
        while(newLabel>ddMax){                          \
            ++ddMax;                                    \
            initBucket((ddMax + buckets));              \
        }                                               \
    }                                                   \
}

/* add component into active list */
#define aAdd(l, curComp){                   \
    com_next = l->firstActive;              \
    curComp->bNext = com_next;              \
    curComp->bPrev = sentinel;              \
    com_next->bPrev = curComp;              \
    l->firstActive = curComp;               \
}

/* remove component into active list */
#define aRemove(l, curComp){                \
    com_next = curComp->bNext;              \
    if(l->firstActive == curComp){          \
        l->firstActive = com_next;          \
    }else{                                  \
        com_prev = curComp->bPrev;          \
        com_prev->bNext = com_next;         \
        com_next->bPrev = com_prev;         \
    }                                       \
}

/* add inactive component */
#define iAdd(l, curComp){                   \
    com_next = l->firstInactive;            \
    curComp->bNext = com_next;              \
    curComp->bPrev = sentinel;              \
    com_next->bPrev = curComp;              \
    l->firstInactive = curComp;             \
}

/* remove inactive component */
#define iDelete(l, curComp){                \
    com_next = curComp->bNext;              \
    if (l->firstInactive == curComp){       \
        l->firstInactive = com_next;        \
    }else{                                  \
        com_prev = curComp->bPrev;          \
        com_prev->bNext = com_next;         \
        com_next->bPrev = com_prev;         \
    }                                       \
}

/* ----------- container macros ------------ */
/* clear stack */
#define stackAdd(head,curComp){        \
    curComp->cNext = head;             \
    head = curComp;                    \
}

/* queue */
#define queueAdd(curComp){              \
    com_prev = sentinel->cNext;         \
    com_prev->cNext = curComp;          \
    curComp->cNext = sentinel;          \
    sentinel->cNext = curComp;          \
}

/* --------------------------functions ------------------------------- */
/* check whether two arrays are the same */
bool checkSame(int *bound1,int *bound2, int *endP){       
    while(bound1!=endP){
        if(*bound1!=*bound2)
            return false;
        else{
            ++bound1;
            ++bound2;
        }
    }
    return true;
}
/* allocate memory */
int allocDS(){
    totalNode = 0;
    buckets = new bucket[bucketSize];  /* one possible label, one bucket */
    tempCut = new int[tempT1];
    sentinel = new component;      /* set it as a special component */
    clearHead = sentinel;
    colNode = T2*2;
    colNodeNum = colNode-2;

    accumNumNode = new llong*[N];
    for(int gID = 0; gID<N; gID++){
        accumNumNode[gID] = new llong[T1];
        accumNumNode[gID][0] = 0;
        for(int y=0;y<tempT1;y++){
            accumNumNode[gID][y+1] = accumNumNode[gID][y] + upGraphBound[gID][y]-lowGraphBound[gID][y];
        }
        totalNode += accumNumNode[gID][tempT1];
    }

    /* flow: nPair * T1-1 * T2-1 * 2: pairID*(T1-1 * T2-1*2) + y*(T2-1*2) + x*2 + z 
    if nodes in each graph is not the same, the edges are the intersection */
    /* inOutFlow: N * T1-1 * T2-1 * 2: gID*(T1-1 * T2-1*2) + y*(T2-1*2) + x*2 + z 
    if nodes in each graph is not the same, preset the flow */
    /* gRelations */
    /* init comlabels, 4D: N X (T1-1) X (T2-1) X 2: gID, y, x, 2*/
    inOutFlow = new capType*[N];
    comLabels = new component**[N];
    for(int gID = 0;gID<N;++gID){
        inOutFlow[gID] = new capType[accumNumNode[gID][tempT1]]();
        comLabels[gID] = new component*[accumNumNode[gID][tempT1]];
    }
    flow = new capType*[nPair];
    accumEdgeNum = new llong*[nPair]();
    neiInfo* curNeiIfo;
    gRelations = new neiInfo[N*maxNeiNum];
    addNeiCnt = new int[N]();

    int curPos;
    int height;
    int gID1;
    int gID2;
    int cut1;
    int cut2;
    int low1;
    int low2;
    int low;
    int up1;
    int up2;
    int up;
    llong pos;
    llong pos1;
    llong pos2;
    capType curCap;
    for(int pairID = 0;pairID<nPair;++pairID){
        /* gRelations */
        gID1 = Gij[pairID*2];
        gID2 = Gij[pairID*2+1];
        curPos = gID1*maxNeiNum+addNeiCnt[gID1];
        gRelations[curPos].gID2 = gID2;
        gRelations[curPos].flowDir = 1;
        gRelations[curPos].pairID = pairID;
        curPos = gID2*maxNeiNum+addNeiCnt[gID2];
        gRelations[curPos].gID2 = gID1;
        gRelations[curPos].flowDir = -1;
        gRelations[curPos].pairID = pairID;
        ++addNeiCnt[gID1];
        ++addNeiCnt[gID2];

        /* define flows */
        accumEdgeNum[pairID] = new llong[T1];
        accumEdgeNum[pairID][0] = 0;
        for(int y = 0;y<tempT1;y++){
            accumEdgeNum[pairID][y+1] = accumEdgeNum[pairID][y] + max(0,min(upGraphBound[gID1][y],upGraphBound[gID2][y]) - max(lowGraphBound[gID1][y],lowGraphBound[gID2][y]));;
        }
        flow[pairID] = new capType[accumEdgeNum[pairID][tempT1]]();
        curCap = neiCap[pairID];
        if(winSize<min(T1,T2)-1){
            for(int y = 0;y<tempT1;y++){
                low1 = lowGraphBound[gID1][y];
                low2 = lowGraphBound[gID2][y];
                up1 = upGraphBound[gID1][y];
                up2 = upGraphBound[gID2][y];

                /* preset flow if graph time window is different*/
                pos = accumNumNode[gID1][y];
                height = min(low2,up1)-low1;
                for(int x=0;x<height;x++)
                    inOutFlow[gID1][pos+x] -= curCap; /* flow into gID1 */

                pos = accumNumNode[gID2][y];
                height = min(low1,up2)-low2;
                for(int x=0;x<height;x++)
                    inOutFlow[gID2][pos+x] -= curCap; /* flow into gID2 */

                pos = accumNumNode[gID2][y] + max(0,up1 - low2);
                height = up2-max(up1,low2);
                for(int x=0;x<height;x++)
                    inOutFlow[gID2][pos+x] += curCap; /* flow out from gID2 */

                pos = accumNumNode[gID1][y] + max(0,up2 - low1);
                height = up1-max(up2,low1);
                for(int x=0;x<height;x++)
                    inOutFlow[gID1][pos+x] += curCap; /* flow out from gID1 */

                /* preset flow due to different cut*/
                cut1 = initialCut[gID1*tempT1 + y];
                cut2 = initialCut[gID2*tempT1 + y];
                low = max(low1,low2);
                up = min(up1,up2);
                cut1 = min(max(cut1,low),up);
                cut2 = min(max(cut2,low),up);

                pos1 = accumNumNode[gID1][y] - low1;
                pos2 = accumNumNode[gID2][y] - low2;
                pos = accumEdgeNum[pairID][y] - low;
                for(int x = cut1;x<cut2;++x){
                    flow[pairID][pos+x] -= curCap;
                    inOutFlow[gID1][pos1+x] -= curCap;
                    inOutFlow[gID2][pos2+x] += curCap;
                }

                for(int x = cut2;x<cut1;++x){
                    flow[pairID][pos+x] += curCap;
                    inOutFlow[gID1][pos1+x] += curCap;
                    inOutFlow[gID2][pos2+x] -= curCap;
                }
            }
        }else{
            for(int y = 0;y<tempT1;y++){
                /* preset flow due to different cut*/
                cut1 = initialCut[gID1*tempT1 + y];
                cut2 = initialCut[gID2*tempT1 + y];
                pos = accumEdgeNum[pairID][y];
                for(int x = cut1;x<cut2;++x){
                    flow[pairID][pos+x] -= curCap;
                    inOutFlow[gID1][pos+x] -= curCap;
                    inOutFlow[gID2][pos+x] += curCap;
                }

                for(int x = cut2;x<cut1;++x){
                    flow[pairID][pos+x] += curCap;
                    inOutFlow[gID1][pos+x] += curCap;
                    inOutFlow[gID2][pos+x] -= curCap;
                }
            }
        }
    }

    /* temporal variable*/
    Dmatrix = new capType*[T1];
    Rmatrix = new capType*[T1];
    dirs = new int*[T1];
    revDirs = new int*[T1];
    for (int i = 0; i < T1; ++i){
        Dmatrix[i] = new capType[T2];
        Rmatrix[i] = new capType[T2];
        dirs[i] = new int[T2];
        revDirs[i] = new int[T2];
    }

    minCutColumn = new capType[colNode];
    pushedFlow = new capType[colNode];
    sourceModify = new capType[colNode*T1];
    sinkModify = new capType[colNode*T1];
    totalModify = new capType[colNode*T1];
    
    /* initialize parameters*/
    initBucket(buckets);       /* bucket[0] and bucket[1], initialize */
    initBucket((buckets+1));
    aMax = 1;
    aMin = 0;
    ddMax = 1;
    dMax = 1;
    sentinel->d = totalNode; 
    preLabel = totalNode;
    // nodeOpCnt = 0;
    // compCntSinceUpdate = 0;

    return (0);
} /* end of allocate */
/* update component in comLabels */
void updateComLabels(component *tempComp,component *curComp){
    int startY = tempComp->startY;
    int endY = tempComp->endY;
    int gID = tempComp->gID;
    int *lowerBound = tempComp->lowerBound;
    int *upperBound = tempComp->upperBound;
    llong pos;
    for (int y = startY; y<endY; ++y){
        pos = accumNumNode[gID][y]-lowGraphBound[gID][y];
        for(int x=lowerBound[y];x<upperBound[y];++x){
            comLabels[gID][pos+x] = curComp;
        }
    }
}
/* set the part below initial cut as sink */
void initialComLabels(){
    int cut;
    llong pos;
    int low;
    for(int gID = 0;gID<N;++gID){
        for(int y=0;y<tempT1;++y){
            cut = initialCut[gID*tempT1 + y];
            low = lowGraphBound[gID][y];
            pos = accumNumNode[gID][y];
            for(int x=0;x<cut-low;++x){
                comLabels[gID][pos+x] = sentinel;
            }
        }
    }
}

/* within relation for global relabel */
void withinLinkageExcess(component *curComp){
    int startY = curComp->startY;
    int endY = curComp->endY;
    int *lowerBound = curComp->lowerBound;
    int *upperBound = curComp->upperBound;
    int gID = curComp->gID;
    int x00;
    int x11;
    int low;
    component *tempComp;
    component** base = comLabels[gID];
    /* find within the same subgraph */
    /* lower side */
    for (int y=startY;y<endY;++y){
        x00 = lowerBound[y];
        low = lowGraphBound[gID][y];
        if(x00==low)
            continue;
        tempComp = *(base + accumNumNode[gID][y] + x00 - 1 - low);
        if(tempComp->d<totalNode)
            withinLinkage[tempComp].insert(curComp);
    }
    /* right side */
    for (int y=startY;y<min(endY,T1-2);++y){
        low = lowGraphBound[gID][y+1];
        x00 = ceil(lowerBound[y]);
        x00 = max(x00,low>>2);
        x11 = min((y<endY-1?floor(lowerBound[y+1]):ceil(upperBound[endY-1])),ceil(upperBound[y]));
        base = comLabels[gID] + accumNumNode[gID][y+1] + 1 - low;
        for (int x=x00;x<x11;++x){
            tempComp = *(base + x*2);
            if(tempComp->d<totalNode)
                withinLinkage[tempComp].insert(curComp);
        }
    }
}
/* within relation for global relabel */
void withinLinkageDeficit(component *curComp){
    int startY = curComp->startY;
    int endY = curComp->endY;
    int *lowerBound = curComp->lowerBound;
    int *upperBound = curComp->upperBound;
    int gID = curComp->gID;
    int x00;
    int x11;
    int up;
    component *tempComp;
    component** base = comLabels[gID];
    /* find within the same subgraph */
    /* upper side */
    for (int y=startY;y<endY;++y){
        x00 = upperBound[y];
        up = upGraphBound[gID][y];
        if(x00==up)
            continue;
        tempComp = *(base + accumNumNode[gID][y] + x00  - lowGraphBound[gID][y]);
        if(tempComp->d<totalNode)
            withinLinkage[tempComp].insert(curComp);
    }
    /* left side */
    for (int y=max(startY,1);y<endY;++y){
        up = upGraphBound[gID][y-1];
        x00 = y>startY?ceil(upperBound[y-1]):floor(lowerBound[startY]);
        x11 = floor(upperBound[y]);
        x11 = min(x11,(up+1)>>1);
        base = comLabels[gID] + accumNumNode[gID][y-1] - lowGraphBound[gID][y-1];
        for (int x=x00;x<x11;++x){
            tempComp = *(base + x*2);
            if(tempComp->d<totalNode)
                withinLinkage[tempComp].insert(curComp);
        }
    }
}
/* neighbor relation for global relabel */
void neiLinkageExcess(){
    component *curComp;
    component *neiComp;
    int gID1;
    int gID2;
    int pos;
    int low1;
    int low2;
    int up1;
    int up2;
    int low;
    int up;
    component** com_ad;
    component** com_ad2;
    capType* flow_ad;
    for(int pairID = 0;pairID<nPair;++pairID){   
        if(neiCap[pairID]==0)
            continue;
        gID1 = Gij[2*pairID];
        gID2 = Gij[2*pairID+1];
        com_ad = comLabels[gID1];
        com_ad2 = comLabels[gID2];
        flow_ad = flow[pairID];
        for(int y=0;y<tempT1;++y){
            low1 = lowGraphBound[gID1][y];
            low2 = lowGraphBound[gID2][y];
            low = max(low1,low2);
            up1 = upGraphBound[gID1][y];
            up2 = upGraphBound[gID2][y];
            up = min(up1,up2);
            // positive direction   curComp->neiComp
            pos = up - 1;
            while(pos>=low){
                curComp = *(com_ad+pos+accumNumNode[gID1][y]-low1);
                neiComp = *(com_ad2+pos+accumNumNode[gID2][y]-low2);
                if(curComp->d>=totalNode || neiComp->d >=totalNode) // continue to search lower nodes, meaningless
                    break;
                if(neiLinkage[neiComp].find(curComp)!=neiLinkage[neiComp].end()){ // already add such relation
                    pos = max(curComp->lowerBound[y],neiComp->lowerBound[y]) - 1;   // jump to next neighbor relation
                    continue;
                }
                if(*(flow_ad + accumEdgeNum[pairID][y] + pos - low)<neiCap[pairID]){
                    neiLinkage[neiComp].insert(curComp);                         // add relation
                    pos = max(curComp->lowerBound[y],neiComp->lowerBound[y]) - 1;   // jump to next neighbor relation
                    continue;
                }
                --pos; // check next edge
            }

            // reverse direction    neiComp->curComp
            pos = up - 1;
            while(pos>=low){
                curComp = *(com_ad+pos+accumNumNode[gID1][y]-low1);
                neiComp = *(com_ad2+pos+accumNumNode[gID2][y]-low2);
                if(curComp->d>=totalNode || neiComp->d >=totalNode) // continue to search lower nodes, meaningless
                    break;
                if(neiLinkage[curComp].find(neiComp)!=neiLinkage[curComp].end()){ // already add such relation
                    pos = max(curComp->lowerBound[y],neiComp->lowerBound[y]) - 1;   // jump to next neighbor relation
                    continue;
                }
                if(-*(flow_ad + pos + accumEdgeNum[pairID][y] - low)<neiCap[pairID]){            // times -1
                    neiLinkage[curComp].insert(neiComp);                         // add relation
                    pos = max(curComp->lowerBound[y],neiComp->lowerBound[y]) - 1;   // jump to next neighbor relation
                    continue;
                }
                --pos; // check next edge
            }
        }
    }
}
/* neighbor relation for global relabel */
void neiLinkageDeficit(){
    component *curComp;
    component *neiComp;
    int pos;
    int pos_ad;
    int gID1;
    int gID2;
    int low1;
    int low2;
    int up1;
    int up2;
    int low;
    int up;
    component** com_ad;
    component** com_ad2;
    capType* flow_ad;
    for(int pairID = 0;pairID<nPair;++pairID){   
        if(neiCap[pairID]==0)
            continue;
        gID1 = Gij[2*pairID];
        gID2 = Gij[2*pairID+1];
        com_ad = comLabels[gID1];
        com_ad2 = comLabels[gID2];
        flow_ad = flow[pairID];
        for(int y=0;y<tempT1;++y){
            low1 = lowGraphBound[gID1][y];
            low2 = lowGraphBound[gID2][y];
            low = max(low1,low2);
            up1 = upGraphBound[gID1][y];
            up2 = upGraphBound[gID2][y];
            up = min(up1,up2);
            // positive direction   curComp->neiComp
            pos = low;
            while(pos<up){
                curComp = *(com_ad+pos+accumNumNode[gID1][y]-low1);
                neiComp = *(com_ad2+pos+accumNumNode[gID2][y]-low2);
                if(curComp->d>=totalNode || neiComp->d >=totalNode) // continue to search lower nodes, meaningless
                    break;
                if(neiLinkage[curComp].find(neiComp)!=neiLinkage[curComp].end()){ // already add such relation
                    pos = min(curComp->upperBound[y],neiComp->upperBound[y]);   // jump to next neighbor relation
                    continue;
                }
                if(*(flow_ad+accumEdgeNum[pairID][y]+pos-low)<neiCap[pairID]){
                    neiLinkage[curComp].insert(neiComp);                         // add relation
                    pos = min(curComp->upperBound[y],neiComp->upperBound[y]);   // jump to next neighbor relation
                    continue;
                }
                ++pos; // check next edge
            }
            // reverse direction    neiComp->curComp
            pos = low;
            while(pos<up){
                curComp = *(com_ad+pos+accumNumNode[gID1][y]-low1);
                neiComp = *(com_ad2+pos+accumNumNode[gID2][y]-low2);
                if(curComp->d>=totalNode || neiComp->d >=totalNode) // continue to search lower nodes, meaningless
                    break;
                if(neiLinkage[neiComp].find(curComp)!=neiLinkage[neiComp].end()){ // already add such relation
                    pos = min(curComp->upperBound[y],neiComp->upperBound[y]);   // jump to next neighbor relation
                    continue;
                }
                if(-*(flow_ad+accumEdgeNum[pairID][y]+pos-low)<neiCap[pairID]){    // times -1
                    neiLinkage[neiComp].insert(curComp);                         // add relation
                    pos = min(curComp->upperBound[y],neiComp->upperBound[y]);   // jump to next neighbor relation
                    continue;
                }
                ++pos; // check next edge
            }
        }
    }
}
/* global relabel */
void globalRelabel(bool isPushExcess){
    bucket *l;              /* current list  */
    llong curLabel = 0;          /* current label */
    component* curComp;
    component* neiComp;
    component* curQueue = sentinel;
    component* nextQueue = sentinel;
    component* tmpQueue;
    // compCntSinceUpdate = 0;

    // linkage
    if(isPushExcess){   // sink as root
        neiLinkageExcess();
        for (l = buckets; l <= (buckets + dMax); ++l){
            for(curComp = l->firstInactive; curComp != sentinel; curComp = curComp->bNext)
                withinLinkageExcess(curComp);
            for(curComp = l->firstActive; curComp != sentinel; curComp = curComp->bNext)
                withinLinkageExcess(curComp);
        }
    }else{              // source as root
        neiLinkageDeficit();
        for (l = buckets; l <= (buckets + dMax); ++l){
            for(curComp = l->firstInactive; curComp != sentinel; curComp = curComp->bNext)
                withinLinkageDeficit(curComp);
            for(curComp = l->firstActive; curComp != sentinel; curComp = curComp->bNext)
                withinLinkageDeficit(curComp);
        }
    }

    /* 0-label component: set check status, add into list */
    l = buckets;
    for(curComp = l->firstActive; curComp != sentinel; curComp = curComp->bNext){
        stackAdd(nextQueue,curComp);
    }
    for(curComp = l->firstInactive; curComp != sentinel; curComp = curComp->bNext){
        stackAdd(nextQueue,curComp);
    }
    
    /* Other components set check status, set label */
    for (l = buckets+1; l <= (buckets + dMax); ++l){
        for(curComp = l->firstInactive; curComp != sentinel; curComp = curComp->bNext){
            curComp->d = totalNode;
        }
        for(curComp = l->firstActive; curComp != sentinel; curComp = curComp->bNext){
            curComp->d = totalNode;
        }
    }

     /* modify label */
    while(1){
        curQueue = nextQueue;
        nextQueue = sentinel;
        if(curQueue==sentinel)
            break;
        while(curQueue!=sentinel){
            curComp = curQueue;
            curQueue = curComp->cNext;
            for (auto it = withinLinkage[curComp].begin();it != withinLinkage[curComp].end(); ++it){
                neiComp = *it;
                if(neiComp->d > curLabel){     /* within same graph */
                    neiComp->d = curLabel;
                    stackAdd(curQueue,neiComp);
                }
            }
            for (auto it = neiLinkage[curComp].begin();it != neiLinkage[curComp].end(); ++it){
                neiComp = *it;
                if(neiComp->d > curLabel + 1){ /* different subgraphs */
                    neiComp->d = curLabel+1;
                    stackAdd(nextQueue,neiComp);
                }
            }
        }
        ++curLabel; 
    }
    
    /* Remove components above gap */
    for (l = buckets; l <= (buckets + dMax); ++l){
        for(curComp = l->firstActive; curComp != sentinel; curComp = curComp->bNext){
            if(curComp->d==totalNode){      /* above gap */
                clearComp(curComp);
                stackAdd(clearHead,curComp);   /* need its label when find neighbor */
            }else{
                stackAdd(curQueue,curComp);
            }
        }
        for(curComp = l->firstInactive; curComp != sentinel; curComp = curComp->bNext){
            if(curComp->d==totalNode){
                clearComp(curComp);
                stackAdd(clearHead,curComp); /* need its label when find neighbor */
            }else{
                stackAdd(curQueue,curComp);
            }
        }
        initBucket(l);  /* initialize current bucket */
    }

    aMin = 0;
    aMax = 1;
    dMax = 0;
    bucketMaintain(curLabel-1);
    /* add components into bucket */
    while(curQueue!=sentinel){
        curComp = curQueue;
        l = buckets + curComp->d;
        if(curComp->activeState){
            aAdd(l,curComp);
        }else{
            iAdd(l,curComp);
        }
        curQueue = curQueue->cNext;
    }

    /* clear reverse relation */
    for(auto it = withinLinkage.begin();it!=withinLinkage.end();++it)
        it->second.clear();
    for(auto it = neiLinkage.begin();it!=neiLinkage.end();++it)
        it->second.clear();
    withinLinkage.clear();
    neiLinkage.clear();
}
/* DTW as within push*/
void pushWithinGraphExcess(component *curComp){
    int gID = curComp->gID;
    int startY = curComp->startY;
    int endY = curComp->endY;
    int *upperBound = curComp->upperBound;   /* For label-0 component, upperbound is all T2-1. */
    int *lowerBound = curComp->lowerBound;
    int startX = floor(lowerBound[startY]);
    int endX = ceil(upperBound[endY-1]);
    int dir;
    int x0;
    int x1;
    int pos1;
    int pos2;
    capType* dist_ad;
    capType* inOutFlow_ad;
    /* source, sink modify according to in_out flow 
    link to source, add edges below
    link to sink, add edges above
    y: the edge between node y->y+1
    x: the edge between node x->x+1
    z: 0 is right edge, 1 is up+right inclined edge */
    for (int y = startY; y < endY; ++y){
        pos1 = y*colNode + lowerBound[y];
        pos2 = y*colNode + upperBound[y];
        inOutFlow_ad = inOutFlow[gID] + accumNumNode[gID][y] + upperBound[y] - lowGraphBound[gID][y];
        /* source part */
        sourceModify[pos2] = 0;
        for (int k = pos2-1; k >= pos1; --k){
            --inOutFlow_ad;
            sourceModify[k] = sourceModify[k+1] + max(0,-*(inOutFlow_ad));
        }
        /* sink part */
        sinkModify[pos1] = 0;
        for (int k = pos1+1; k <= pos2; ++k){
            sinkModify[k] = sinkModify[k-1] + max(0,*inOutFlow_ad);
            ++inOutFlow_ad;
        }
        // no need to calculate totalModify since only use once
    }

    /* Dynamic programming */
    dist_ad = distMatrix[gID] + startY*T2;
    Dmatrix[startY][startX] = 0;
    /* The first column */
    for (int x = startX+1; x <= floor(upperBound[startY]); ++x){
        Dmatrix[startY][x] = Dmatrix[startY][x-1] + *(dist_ad + x);
        dirs[startY][x] = 1;
    }
    
    /* Other columns */
    for (int y = startY+1; y <= endY; ++y){
        dist_ad = distMatrix[gID] + y*T2;
        x0 = ceil(lowerBound[y-1]);
        pos2 = (y-1)*colNode + lowerBound[y-1];
        if(x0 != floor(lowerBound[y-1])){
            Cxy = Dmatrix[y-1][x0-1] + *(dist_ad+x0) + sourceModify[pos2] + sinkModify[pos2];
            ++pos2;
        }else
            Cxy = CAP_MAX;

        if(x0 <= floor(upperBound[y-1])){
            Cy = Dmatrix[y-1][x0] + *(dist_ad+x0) + sourceModify[pos2] + sinkModify[pos2];
        }else
            Cy = CAP_MAX;

        minV = Cy;
        dir = 3;
        if (AisNonLargerB(Cxy,minV)){
            minV = Cxy;
            dir = 2;
        }
        Dmatrix[y][x0] = minV;
        dirs[y][x0] = dir;

        for (int x = x0+1; x<=floor(upperBound[y-1]); ++x) {
            /* up */
            Cx = Dmatrix[y][x-1] + *(dist_ad+x);          
            /* up+right */
            ++pos2;
            Cxy = Dmatrix[y-1][x-1] + *(dist_ad+x) + sourceModify[pos2] + sinkModify[pos2];
            /* right */
            ++pos2;
            Cy = Dmatrix[y-1][x] + *(dist_ad+x) + sourceModify[pos2] + sinkModify[pos2];
            /* get min */
            minV = Cy;
            dir = 3;
            if (AisNonLargerB(Cxy,minV)){
                minV = Cxy;
                dir = 2;
            }
            if (AisNonLargerB(Cx,minV)){
                minV = Cx;
                dir = 1;
            }
            
            /* update */
            Dmatrix[y][x] = minV;
            dirs[y][x] = dir;
        }

        x0 = ceil(upperBound[y-1]);
        if(x0<<1 != upperBound[y-1] && upperBound[y-1]>lowerBound[y-1]){   // not the same block
            Cx = Dmatrix[y][x0-1] + *(dist_ad+x0);
            ++pos2;
            Cxy = Dmatrix[y-1][x0-1] + *(dist_ad+x0) + sourceModify[pos2] + sinkModify[pos2];
            /* get min */
            minV = Cxy;
            dir = 2;
            if (AisNonLargerB(Cx,minV)){
                minV = Cx;
                dir = 1;
            }
            /* update */
            Dmatrix[y][x0] = minV;
            dirs[y][x0] = dir;
        }

        x1 = y<endY?floor(upperBound[y]):endX;
        for(int x=x0+1;x<=x1;++x){
            Dmatrix[y][x] = Dmatrix[y][x-1] + *(dist_ad+x);
            dirs[y][x] = 1;
        }
    }

    /* track temporal cut */
    trackBack();
    statusChanged = true;
}
/* DTW as within push*/
void pushWithinGraphDeficit(component *curComp){
    int gID = curComp->gID;
    int startY = curComp->startY;
    int endY = curComp->endY;
    int *upperBound = curComp->upperBound;   /* For label-0 component, upperbound is all T2-1. */
    int *lowerBound = curComp->lowerBound;
    int startX = floor(lowerBound[startY]);
    int endX = ceil(upperBound[endY-1]);
    int dir;
    int x0;
    int x1;
    int pos1;
    int pos2;
    capType* dist_ad;
    capType* inOutFlow_ad;
    /* source, sink modify according to in_out flow 
    link to source, add edges below
    link to sink, add edges above
    y: the edge between node y->y+1
    x: the edge between node x->x+1
    z: 0 is right edge, 1 is up+right inclined edge */
    for (int y = startY; y < endY; ++y){
        pos1 = y*colNode + lowerBound[y];
        pos2 = y*colNode + upperBound[y];
        inOutFlow_ad = inOutFlow[gID] + accumNumNode[gID][y] + upperBound[y] - lowGraphBound[gID][y];
        /* source part */
        sourceModify[pos2] = 0;
        for (int k = pos2-1; k >= pos1; --k){
            --inOutFlow_ad;
            sourceModify[k] = sourceModify[k+1] + max(0,-*(inOutFlow_ad));
        }
        /* sink part */
        sinkModify[pos1] = 0;
        for (int k = pos1+1; k <= pos2; ++k){
            sinkModify[k] = sinkModify[k-1] + max(0,*inOutFlow_ad);
            ++inOutFlow_ad;
        }
        // no need to calculate totalModify since only use once
    }

    /* Rmatrix: Dynamic programming */
    dist_ad = distMatrix[gID] + endY*T2;
    Rmatrix[endY][endX] = 0;
    /* The last column */
    for (int x = endX-1;x<<1 >=lowerBound[endY-1];--x){
        Rmatrix[endY][x] = Rmatrix[endY][x+1] + *(dist_ad + x + 1);
        revDirs[endY][x] = 1;
    }
    /* Other columns */
    for (int y = endY-1;y>=startY;--y){
        dist_ad = distMatrix[gID] + (y+1)*T2;
        x1 = floor(upperBound[y]);
        pos2 = y*colNode + upperBound[y];
        // x1 position
        if(x1<<1 != upperBound[y]){
            Cxy = Rmatrix[y+1][x1+1] + *(dist_ad+ x1 +1) + sourceModify[pos2] + sinkModify[pos2];
            --pos2;
        }else
            Cxy = CAP_MAX;

        if(x1<<1 >= lowerBound[y])
            Cy = Rmatrix[y+1][x1] + *(dist_ad+ x1) + sourceModify[pos2] + sinkModify[pos2];
        else
            Cy = CAP_MAX;

        minV = Cy;
        dir = 3;
        if (AisNonLargerB(Cxy,minV)){
            minV = Cxy;
            dir = 2;
        }
        revDirs[y][x1] = dir;
        Rmatrix[y][x1] = minV;

        for (int x = x1-1; x>=ceil(lowerBound[y]); --x){
            /* up */
            Cx = Rmatrix[y][x+1] + *(dist_ad+x+1-T2);

            /* up + right */
            --pos2;
            Cxy = Rmatrix[y+1][x+1] + *(dist_ad+x+1) + sourceModify[pos2] + sinkModify[pos2];

            /* right */
            --pos2;
            Cy = Rmatrix[y+1][x] + *(dist_ad+x) + sourceModify[pos2] + sinkModify[pos2];
            
            /* get min value */
            minV = Cy;
            dir = 3;
            if (AisNonLargerB(Cxy,minV)){
                minV = Cxy;
                dir = 2;
            }
            if (AisNonLargerB(Cx,minV)){
                minV = Cx;
                dir = 1;
            }

            revDirs[y][x] = dir;
            Rmatrix[y][x] = minV;
        }

        x0 = floor(lowerBound[y]);
        if(x0<<1 != lowerBound[y] && lowerBound[y]<upperBound[y]){
            Cx = Rmatrix[y][x0+1] + *(dist_ad-T2+x0+1);
            --pos2;
            Cxy = Rmatrix[y+1][x0+1] + *(dist_ad+x0+1) + sourceModify[pos2] + sinkModify[pos2];
            minV = Cxy;
            dir = 2;
            if (AisNonLargerB(Cx,minV)){
                minV = Cx;
                dir = 1;
            }
            revDirs[y][x0] = dir;
            Rmatrix[y][x0] = minV;
        }

        for(int x=x0-1;x>=(y>startY?ceil(lowerBound[y-1]):startX);--x){
            Rmatrix[y][x] = Rmatrix[y][x+1] + *(dist_ad-T2+x+1);
            revDirs[y][x] = 1;
        }
    }

    /* track temporal cut */
    revTrackBack();
    statusChanged = true;
}
/* update after new cut occurs */
void updateWithinPushExcess(component *curComp){
    int *lowerBound = curComp->lowerBound;
    int *upperBound = curComp->upperBound;
    int startY = curComp->startY;
    int endY = curComp->endY;
    int gID = curComp->gID;
    /* update components for within push. Segment */
    if(checkSame(tempCut+startY,upperBound+startY,tempCut+endY)){                  /* the whole component is active */
        aMax = 1;
        dMax = max(1,dMax);
        aAdd((buckets+1),curComp);
        curComp->d = 1;
        return;
    }

    curComp->activeState = false;
    iAdd(buckets,curComp);
    if(checkSame(tempCut+startY,lowerBound+startY,tempCut+endY)){                  /* the whole component is inactive */
        return;
    }

    aMax = 1;
    dMax = max(1,dMax);
    int y0 = curComp->startY;
    int y1 = curComp->endY;
    bool newCompnent = true;            /* whether check next y0 */
    int *newUpperBound;
    int *newLowerBound;
    component *newComp;

    /* Need to split */
    /* Update current component */
    newLowerBound = new int[tempT1];
    copyVector(tempCut,newLowerBound,y0,y1);
    curComp->lowerBound = newLowerBound;
    
    for (int y=startY; y<endY; ++y){
        if (tempCut[y]!=upperBound[y]){
            y0 = y;
            break;
        }
    }
    for (int y=endY-1; y>=startY; --y){
        if (tempCut[y]!=upperBound[y]){
            y1 = y+1;
            break;
        }
    }
    curComp->startY = y0;
    curComp->endY = y1;

    /* newComponent */
    y0 = startY;
    y1 = endY;
    int y = startY+1;
    while (y<=endY)    {
        if(tempCut[y-1]==lowerBound[y-1]){
            ++y;
            continue;
        }
        
        if (newCompnent){
            y0 = y-1;                       /* new startY */
            newCompnent = false;                /* already find y0 */
        }

        if(y==endY || ceil(tempCut[y-1]) <= floor(lowerBound[y])){  /* segment condition */
            y1 = y;                         /* new endY */
            newCompnent = true;                /* need to check next y0 */
            /* construct component */
            newComp = new component;
            newComp->gID = gID;
            newComp->startY = y0;
            newComp->endY = y1;
            newComp->d = 1;
            newComp->activeState = true;
            newLowerBound = new int[tempT1];
            newUpperBound = new int[tempT1];
            copyVector(lowerBound,newLowerBound,y0,y1);
            copyVector(tempCut,newUpperBound,y0,y1);
            newComp->lowerBound = newLowerBound;
            newComp->upperBound = newUpperBound;
            aAdd((buckets+1),newComp);
            updateComLabels(newComp,newComp);
            y0 = y;
        }
        ++y;
    }
    
    delete[] lowerBound;
}
/* update after new cut occurs */
void updateWithinPushDeficit(component *curComp){
    int *lowerBound = curComp->lowerBound;
    int *upperBound = curComp->upperBound;
    int startY = curComp->startY;
    int endY = curComp->endY;
    int gID = curComp->gID;
    /* update components for within push. Segment */
    if(checkSame(tempCut+startY,lowerBound+startY,tempCut+endY)){                  /* the whole component is active */
        aMax = 1;
        dMax = max(1,dMax);
        curComp->d = 1;
        aAdd((buckets+1),curComp);
        return;
    }

    curComp->activeState = false;
    iAdd(buckets,curComp);
    if(checkSame(tempCut+startY,upperBound+startY,tempCut+endY)){                  /* the whole component is inactive */
        return;
    }

    aMax = 1;
    dMax = max(1,dMax);
    int y0 = curComp->startY;
    int y1 = curComp->endY;
    bool newCompnent = true;            /* whether check next y0 */
    int *newUpperBound;
    int *newLowerBound;
    component *newComp;

    /* Need to split */
    /* Update current component */
    newUpperBound = new int[tempT1];
    copyVector(tempCut,newUpperBound,y0,y1);
    curComp->upperBound = newUpperBound;
    
    for (int y=startY; y<endY; ++y){
        if (tempCut[y]!=lowerBound[y]){
            y0 = y;
            break;
        }
    }
    for (int y=endY-1; y>=startY; --y){
        if (tempCut[y]!=lowerBound[y]){
            y1 = y+1;
            break;
        }
    }
    curComp->startY = y0;
    curComp->endY = y1;

    /* newComponent */
    y0 = startY;
    y1 = endY;
    int y = startY+1;
    while (y<=endY)    {
        if(tempCut[y-1]==upperBound[y-1]){
            ++y;
            continue;
        }
        
        if (newCompnent){
            y0 = y-1;                       /* new startY */
            newCompnent = false;                /* already find y0 */
        }

        if(y==endY || ceil(upperBound[y-1]) <= floor(tempCut[y])){  /* segment condition */
            y1 = y;                         /* new endY */
            newCompnent = true;                /* need to check next y0 */
            /* construct component */
            newComp = new component;
            newComp->gID = gID;
            newComp->startY = y0;
            newComp->endY = y1;
            newComp->d = 1;
            newComp->activeState = true;
            newLowerBound = new int[tempT1];
            newUpperBound = new int[tempT1];
            copyVector(tempCut,newLowerBound,y0,y1);
            copyVector(upperBound,newUpperBound,y0,y1);
            newComp->lowerBound = newLowerBound;
            newComp->upperBound = newUpperBound;
            aAdd((buckets+1),newComp);
            updateComLabels(newComp,newComp);
            y0 = y;
        }
        ++y;
    }
    
    delete[] upperBound;
}
/* initialization for stage one */
void init_StageOne(){
    component *curComp;                         /* current component */
    int gID1;
    int gID2;
    deBugCnt = 0;
    initialComLabels();

    /* each subgraph is one component */
    for (int gID = 0; gID < N; ++gID){
        /* initialize */
        curComp = new component;
        curComp->startY = 0;
        curComp->endY = tempT1;
        curComp->gID = gID;
        curComp->d = 0;
        curComp->activeState = true;
        curComp->lowerBound = new int[tempT1];
        curComp->upperBound = new int[tempT1];
        for (int y = 0; y < tempT1; ++y){
            curComp->lowerBound[y] = initialCut[gID*tempT1+y];
            curComp->upperBound[y] = upGraphBound[gID][y];
        }
        updateComLabels(curComp,curComp);

        /* initialization */
        /* within push + update*/
        pushWithinGraphExcess(curComp);
        updateWithinPushExcess(curComp);
    }

    globalRelabel(true);
} 
/* initialization for stage two */
void init_StageTwo(){
    bucket *l;
    component *curComp;
    int gID1;
    int gID2;

    for (l = buckets;l<=(buckets+dMax);++l){
        for(curComp = l->firstInactive;curComp!=sentinel;curComp=curComp->bNext){
            curComp->d = totalNode;
            clearComp(curComp);
            stackAdd(clearHead,curComp);
        }
        initBucket(l);
    }
    dMax = 0;

    /* each subgraph is one component */
    for (int gID = 0; gID < N; ++gID){
        /* initialize */
        curComp = new component;
        curComp->startY = 0;
        curComp->endY = tempT1;
        curComp->gID = gID;
        curComp->d = 0;
        curComp->activeState = true;
        curComp->lowerBound = new int[tempT1];
        curComp->upperBound = new int[tempT1];
        for (int y = 0; y < tempT1; ++y){
            curComp->upperBound[y] = initialCut[gID*tempT1+y];
            curComp->lowerBound[y] = lowGraphBound[gID][y];
        }
        updateComLabels(curComp,curComp);
        /* initialization */
        /* within push + update*/
        pushWithinGraphDeficit(curComp);
        updateWithinPushDeficit(curComp);
    }
    
    globalRelabel(false);
}
/* gap heuristic */
void gap(bucket *emptyB){
    bucket *l;
    /* set all inactive components above gap to highest label */
    for (l=emptyB+1; l<=(buckets + dMax);++l){
        for (component *tmpComp = l->firstInactive; tmpComp != sentinel; tmpComp = tmpComp->bNext) {
            tmpComp->d = totalNode;
            clearComp(tmpComp);
            stackAdd(clearHead,tmpComp);                     /* need its label when find neighbor */
        }
        l->firstInactive = sentinel;
    }
    dMax = emptyB-buckets-1;
    aMax = dMax;
}
/* update after new cut occurs */
void updateCrossPushExcess(component *curComp){
    llong curLabel = curComp->d;
    bucket *l = buckets + curLabel;
    int *lowerBound = curComp->lowerBound;
    int *upperBound = curComp->upperBound;
    int startY = curComp->startY;
    int endY = curComp->endY;
    int gID = curComp->gID;

    /* check whether all excess pushed out */
    if(checkSame(tempCut+startY,lowerBound+startY,tempCut+endY)){
        curComp->activeState = false;
        iAdd(l,curComp);
        return;
    }

    /* check whether no change */
    if(checkSame(tempCut+startY,upperBound+startY,tempCut+endY)){   /* cut not change, still active */
        aAdd(l,curComp);
        return;
    }

    int y0;
    int y1;
    int y;
    bool newCompnent = true;
    bool flag = true;
    int *newUpperBound;
    int *newLowerBound;
    component *newComp;

    /* Split current region */
    /* active side */
    y0 = startY;
    y1 = endY;
    y = startY + 1;
    while(y<=endY){
        if(tempCut[y-1]==lowerBound[y-1]){
            ++y;
            continue;
        }
        
        if(newCompnent){  /* find new component, update y0 */
            y0 = y-1;
            newCompnent = false;
        }

        if(y==endY || ceil(tempCut[y-1]) <= floor(lowerBound[y])){ /* segment condition */
            y1 = y;
            newCompnent = true;
            /* component update */
            if(flag){
                flag = false;
                curComp->startY = y0;
                curComp->endY = y1;
                newUpperBound = new int[tempT1];
                copyVector(tempCut,newUpperBound,y0,y1);
                curComp->upperBound = newUpperBound;
                aAdd(l,curComp);
            }else{
                newComp = new component;
                newComp->gID = gID;
                newComp->startY = y0;
                newComp->endY = y1;
                newComp->d = curLabel;
                newComp->activeState = true;
                newLowerBound = new int[tempT1];
                newUpperBound = new int[tempT1];
                copyVector(lowerBound,newLowerBound,y0,y1);
                copyVector(tempCut,newUpperBound,y0,y1);
                newComp->lowerBound = newLowerBound;
                newComp->upperBound = newUpperBound;
                aAdd(l,newComp);
                updateComLabels(newComp,newComp);
            }
            y0 = y;
        }
        ++y;
    }

    /* inactive side */
    newCompnent = true;
    y0 = startY;
    y1 = endY;
    y = startY + 1;
    while(y<=endY){
        if(tempCut[y-1]==upperBound[y-1]){
            ++y;
            continue;
        }
        
        if(newCompnent){ /* find new component, update y0 */
            y0 = y-1;
            newCompnent = false;
        }
        if(y==endY || ceil(upperBound[y-1]) <= floor(tempCut[y])){ /* segment condition */
            y1 = y;
            newCompnent = true;
            /* component update */
            newComp = new component;
            newComp->gID = gID;
            newComp->startY = y0;
            newComp->endY = y1;
            newComp->d = curLabel;
            newComp->activeState = false;
            newLowerBound = new int[tempT1];
            newUpperBound = new int[tempT1];
            copyVector(tempCut,newLowerBound,y0,y1);
            copyVector(upperBound,newUpperBound,y0,y1);
            newComp->lowerBound = newLowerBound;
            newComp->upperBound = newUpperBound;
            iAdd(l,newComp);
            updateComLabels(newComp,newComp);
            y0 = y;
        }
        ++y;
    }

    delete[] upperBound;
}
/* update after new cut occurs */
void updateCrossPushDeficit(component *curComp){
    llong curLabel = curComp->d;
    bucket *l = buckets + curLabel;
    int *lowerBound = curComp->lowerBound;
    int *upperBound = curComp->upperBound;
    int startY = curComp->startY;
    int endY = curComp->endY;
    int gID = curComp->gID;

    /* check whether all excess pushed out */
    if(checkSame(tempCut+startY,upperBound+startY,tempCut+endY)){
        curComp->activeState = false;
        iAdd(l,curComp);
        return;
    }

    /* check whether no change */
    if(checkSame(tempCut+startY,lowerBound+startY,tempCut+endY)){   /* cut not change, still active */
        aAdd(l,curComp);
        return;
    }

    int y0;
    int y1;
    int y;
    bool newCompnent = true;
    bool flag = true;
    int *newUpperBound;
    int *newLowerBound;
    component *newComp;

    /* Split current region */
    /* active side */
    y0 = startY;
    y1 = endY;
    y = startY + 1;
    while(y<=endY){
        if(tempCut[y-1]==upperBound[y-1]){
            ++y;
            continue;
        }
        
        if(newCompnent){  /* find new component, update y0 */
            y0 = y-1;
            newCompnent = 0;
        }

        if(y==endY || ceil(upperBound[y-1]) <= floor(tempCut[y]) ){ /* segment condition */
            y1 = y;
            newCompnent = true;
            /* component update */
            if(flag){
                flag = false;
                curComp->startY = y0;
                curComp->endY = y1;
                newLowerBound = new int[tempT1];
                copyVector(tempCut,newLowerBound,y0,y1);
                curComp->lowerBound = newLowerBound;
                aAdd(l,curComp);
            }else{
                newComp = new component;
                newComp->gID = gID;
                newComp->startY = y0;
                newComp->endY = y1;
                newComp->d = curLabel;
                newComp->activeState = true;
                newLowerBound = new int[tempT1];
                newUpperBound = new int[tempT1];
                copyVector(tempCut,newLowerBound,y0,y1);
                copyVector(upperBound,newUpperBound,y0,y1);
                newComp->lowerBound = newLowerBound;
                newComp->upperBound = newUpperBound;
                aAdd(l,newComp);
                updateComLabels(newComp,newComp);
            }
            y0 = y;
        }
        ++y;
    }

    /* inactive side */
    newCompnent = true;
    y0 = startY;
    y1 = endY;
    y = startY + 1;
    while(y<=endY){
        if(tempCut[y-1]==lowerBound[y-1]){
            ++y;
            continue;
        }
        
        if(newCompnent){ /* find new component, update y0 */
            y0 = y-1;
            newCompnent = false;
        }

        if(y==endY || ceil(tempCut[y-1]) <= floor(lowerBound[y])){ /* segment condition */
            y1 = y;
            newCompnent = true;
            /* component update */
            newComp = new component;
            newComp->gID = gID;
            newComp->startY = y0;
            newComp->endY = y1;
            newComp->d = curLabel;
            newComp->activeState = false;
            newLowerBound = new int[tempT1];
            newUpperBound = new int[tempT1];
            copyVector(lowerBound,newLowerBound,y0,y1);
            copyVector(tempCut,newUpperBound,y0,y1);
            newComp->lowerBound = newLowerBound;
            newComp->upperBound = newUpperBound;
            iAdd(l,newComp);
            updateComLabels(newComp,newComp);
            y0 = y;
        }
        ++y;
    }

    delete[] lowerBound;
}
/* merge components */
void merge(component* curComp){
    component *tempComp;
    component *nextComp;
    int y0 = curComp->startY;
    int y1 = curComp->endY;
    int *lowerBound = curComp->lowerBound;
    int *upperBound = curComp->upperBound;
    int *tmpLowerBound;
    int *tmpUpperBound;
    int gID = curComp->gID;
    noMerge = false;

    /* use lowerBound to show whether the column is included */
    for (int y=0;y<y0;++y)
        lowerBound[y] = -1;
    for (int y=y1;y<tempT1;++y)
        lowerBound[y] = -1;

    int y00;
    int y11;
    for (tempComp = queueHead; tempComp != sentinel; tempComp=nextComp){
        y00 = tempComp->startY;
        y11 = tempComp->endY;
        tmpLowerBound = tempComp->lowerBound;
        tmpUpperBound = tempComp->upperBound;

        /* update bound */
        for(int y = y00;y<y11;++y){
            if(lowerBound[y]==-1){
                lowerBound[y] = tmpLowerBound[y];
                upperBound[y] = tmpUpperBound[y];
            }else{
                lowerBound[y] = min(lowerBound[y],tmpLowerBound[y]);
                upperBound[y] = max(upperBound[y],tmpUpperBound[y]);
            }
        }
        y0 = min(y0,y00);
        y1 = max(y1,y11);
        /* remove from bucket */
        if(tempComp->activeState){
            aRemove((buckets + tempComp->d),tempComp);
        }else{
            iDelete((buckets + tempComp->d),tempComp);
        }
        updateComLabels(tempComp,curComp);
        clearComp(tempComp);
        nextComp = tempComp->cNext;
        delete tempComp;
    }

    /* update */
    curComp->startY = y0;
    curComp->endY = y1;
}
/* find min label of reachable component in the neighbor subgraph */
llong checkNeiLowestLabelExcess(component* curComp,llong minCrossLabel,llong noNeedCheckLabel){
    //For each column, if linkage, check next column.
    //If label less than curComp->d -1, don't need to check
    //If done, check next.
    int gID;
    int gID2;
    int pairID;
    int flowDir;
    int startY;
    int endY;
    int *lowerBound;
    int *upperBound;
    component *neiComp;
    capType capacity;
    int x;
    int nei_ad;
    capType* flow_ad;
    component** com_ad;
    
    if(winSize>T1-1||winSize>T2-1){
        for(component* tmpComp = curComp;tmpComp!=sentinel;tmpComp=tmpComp->cNext){
            lowerBound = tmpComp->lowerBound;
            upperBound = tmpComp->upperBound;
            gID = tmpComp->gID;
            startY = tmpComp->startY;
            endY = tmpComp->endY;
            nei_ad = gID*maxNeiNum;
            for(int neiPos = 0;neiPos<addNeiCnt[gID];++neiPos){
                pairID = gRelations[nei_ad+neiPos].pairID;
                flowDir = gRelations[nei_ad+neiPos].flowDir;
                gID2 = gRelations[nei_ad+neiPos].gID2;
                capacity = neiCap[pairID]*(1-RESOLUTION);
                for(int y = startY;y<endY;++y){
                    flow_ad = flow[pairID] + y*colNodeNum;
                    com_ad = comLabels[gID2] + y*colNodeNum;
                    x = upperBound[y]-1;
                    while(x>=lowerBound[y]){
                        neiComp = *(com_ad+x);
                        if(neiComp->d<=noNeedCheckLabel){
                            x = neiComp->lowerBound[y] - 1;
                            continue;
                        }
                        if(neiComp->d>=minCrossLabel){ // larger than min label, don't need to check again.
                            break; // jump out of range
                        }
                        if(flowDir*(*(flow_ad+x))<capacity){   // still can send
                            minCrossLabel = neiComp->d; // update label
                            break; // jump out of range. Check next column, since upper laber is smaller than lower
                        }
                        --x;
                    }
                }
            }
        }
    }else{
        int low1;
        int low2;
        int low;
        int up2;
        for(component* tmpComp = curComp;tmpComp!=sentinel;tmpComp=tmpComp->cNext){
            lowerBound = tmpComp->lowerBound;
            upperBound = tmpComp->upperBound;
            gID = tmpComp->gID;
            startY = tmpComp->startY;
            endY = tmpComp->endY;
            nei_ad = gID*maxNeiNum;
            for(int neiPos = 0;neiPos<addNeiCnt[gID];++neiPos){
                pairID = gRelations[nei_ad+neiPos].pairID;
                flowDir = gRelations[nei_ad+neiPos].flowDir;
                gID2 = gRelations[nei_ad+neiPos].gID2;
                capacity = neiCap[pairID]*(1-RESOLUTION);
                for(int y = startY;y<endY;++y){
                    low1 = lowGraphBound[gID][y];
                    low2 = lowGraphBound[gID2][y];
                    up2 = upGraphBound[gID2][y];
                    low = max(low1,low2);
                    flow_ad = flow[pairID] + accumEdgeNum[pairID][y] - low;
                    com_ad = comLabels[gID2] + accumNumNode[gID2][y] - low2;
                    x = min(up2,upperBound[y])-1;
                    while(x>=max(low2,lowerBound[y])){
                        neiComp = *(com_ad+x);
                        if(neiComp->d<=noNeedCheckLabel){
                            x = neiComp->lowerBound[y] - 1;
                            continue;
                        }
                        if(neiComp->d>=minCrossLabel){ // larger than min label, don't need to check again.
                            break; // jump out of range
                        }
                        if(flowDir*(*(flow_ad+x))<capacity){   // still can send
                            minCrossLabel = neiComp->d; // update label
                            break; // jump out of range. Check next column, since upper laber is smaller than lower
                        }
                        --x;
                    }
                }
            }
        }
    }
    return minCrossLabel;
}
/* find min label of reachable component in the neighbor subgraph */
llong checkNeiLowestLabelDeficit(component* curComp,llong minCrossLabel,llong noNeedCheckLabel){
    //For each column, if linkage, check next column.
    //If label less than curComp->d -1, don't need to check
    //If done, check next.
    int gID;
    int gID2;
    int pairID;
    int flowDir;
    int startY;
    int endY;
    int *lowerBound;
    int *upperBound;
    component *neiComp;
    capType capacity;
    int x;
    capType* flow_ad;
    component** com_ad;
    int nei_ad;
    int low1;
    int low2;
    int low;
    int up2;
    if(winSize>T1-1 || winSize>T2-1){
        for(component* tmpComp = curComp;tmpComp!=sentinel;tmpComp=tmpComp->cNext){
            lowerBound = tmpComp->lowerBound;
            upperBound = tmpComp->upperBound;
            gID = tmpComp->gID;
            startY = tmpComp->startY;
            endY = tmpComp->endY;
            nei_ad = gID*maxNeiNum;
            for(int neiPos = 0;neiPos<addNeiCnt[gID];++neiPos){
                pairID = gRelations[nei_ad+neiPos].pairID;
                flowDir = gRelations[nei_ad+neiPos].flowDir;
                gID2 = gRelations[nei_ad+neiPos].gID2;
                capacity = neiCap[pairID]*(1-RESOLUTION);
                for(int y = startY;y<endY;++y){
                    flow_ad = flow[pairID] + y*colNodeNum;
                    com_ad = comLabels[gID2] + y*colNodeNum;
                    x = lowerBound[y];
                    while(x<upperBound[y]){
                        neiComp = *(com_ad+x);
                        if(neiComp->d<=noNeedCheckLabel){ // invalid. Or all cross edges are fullfilled
                            x = neiComp->upperBound[y];   // jump over this component
                            continue;
                        }
                        if(neiComp->d>=minCrossLabel){ // larger than min label, don't need to check again.
                            break; // jump out of range
                        }
                        if(-flowDir*(*(flow_ad+x))<capacity){   // still can send
                            minCrossLabel = neiComp->d; // update label
                            break; // jump out of range. Check next column, since upper label is smaller than lower
                        }
                        ++x;
                    }
                }
            }
        }
    }else{
        for(component* tmpComp = curComp;tmpComp!=sentinel;tmpComp=tmpComp->cNext){
            lowerBound = tmpComp->lowerBound;
            upperBound = tmpComp->upperBound;
            gID = tmpComp->gID;
            startY = tmpComp->startY;
            endY = tmpComp->endY;
            nei_ad = gID*maxNeiNum;
            for(int neiPos = 0;neiPos<addNeiCnt[gID];++neiPos){
                pairID = gRelations[nei_ad+neiPos].pairID;
                flowDir = gRelations[nei_ad+neiPos].flowDir;
                gID2 = gRelations[nei_ad+neiPos].gID2;
                capacity = neiCap[pairID]*(1-RESOLUTION);
                for(int y = startY;y<endY;++y){
                    low1 = lowGraphBound[gID][y];
                    low2 = lowGraphBound[gID2][y];
                    up2 = upGraphBound[gID2][y];
                    low = max(low1,low2);
                    flow_ad = flow[pairID] + accumEdgeNum[pairID][y]-low;
                    com_ad = comLabels[gID2] + accumNumNode[gID2][y]-low2;
                    x = max(low2,lowerBound[y]);
                    while(x<min(up2,upperBound[y])){
                        neiComp = *(com_ad+x);
                        if(neiComp->d<=noNeedCheckLabel){ // invalid. Or all cross edges are fullfilled
                            x = neiComp->upperBound[y];   // jump over this component
                            continue;
                        }
                        if(neiComp->d>=minCrossLabel){ // larger than min label, don't need to check again.
                            break; // jump out of range
                        }
                        if(-flowDir*(*(flow_ad+x))<capacity){   // still can send
                            minCrossLabel = neiComp->d; // update label
                            break; // jump out of range. Check next column, since upper label is smaller than lower
                        }
                        ++x;
                    }
                }
            }
        }
    }
    return minCrossLabel;
}
/* find min label of reachable component in the same subgraph */
llong checkWithinLowestLabelExcess(component* curComp){
    llong minWithinLabel = LLONG_MAX - 1;
    int startY = curComp->startY;
    int endY = curComp->endY;
    int *lowerBound = curComp->lowerBound;
    int *upperBound = curComp->upperBound;
    int gID = curComp->gID;
    int x00;
    int x11;
    int low;
    component *tempComp;
    component** base = comLabels[gID];
    /* find within the same subgraph */
    /* lower side */
    for (int y=startY;y<endY;++y){
        x00 = lowerBound[y];
        low = lowGraphBound[gID][y];
        if(x00>low){
            tempComp = *(base + accumNumNode[gID][y] + x00 - 1 - low);
            if(minWithinLabel>tempComp->d){
                minWithinLabel = tempComp->d;
            }
        }
    }
    /* right side */
    for (int y=startY;y<min(endY,T1-2);++y){
        low = lowGraphBound[gID][y+1];
        x00 = ceil(lowerBound[y]);
        x00 = max(x00,low>>2);
        x11 = min((y<endY-1?floor(lowerBound[y+1]):ceil(upperBound[endY-1])),ceil(upperBound[y]));
        base = comLabels[gID] + accumNumNode[gID][y+1] + 1 - low;
        for (int x=x00;x<x11;++x){
            tempComp = *(base + x*2);
            if(minWithinLabel>tempComp->d){
                minWithinLabel = tempComp->d;
            }
        }
    }
    return minWithinLabel;
}
/* find min label of reachable component in the same subgraph */
llong checkWithinLowestLabelDeficit(component* curComp){
    llong minWithinLabel = LLONG_MAX - 1;
    int startY = curComp->startY;
    int endY = curComp->endY;
    int *lowerBound = curComp->lowerBound;
    int *upperBound = curComp->upperBound;
    int gID = curComp->gID;
    int x00;
    int x11;
    int up;
    component *tempComp;
    component** base = comLabels[gID];
    /* find within the same subgraph */
    /* upper side */
    for (int y=startY;y<endY;++y){
        x00 = upperBound[y];
        up = upGraphBound[gID][y];
        if(x00<up){
            tempComp = *(base + accumNumNode[gID][y] + x00  - lowGraphBound[gID][y]);
            if(minWithinLabel>tempComp->d){
                minWithinLabel = tempComp->d;
            }
        }
    }
    /* left side */
    for (int y=max(startY,1);y<endY;++y){
        up = upGraphBound[gID][y-1];
        x00 = y>startY?ceil(upperBound[y-1]):floor(lowerBound[startY]);
        x11 = floor(upperBound[y]);
        x11 = min(x11,(up+1)>>1);
        base = comLabels[gID] + accumNumNode[gID][y-1] - lowGraphBound[gID][y-1];
        for (int x=x00;x<x11;++x){
            tempComp = *(base + x*2);
            if(minWithinLabel>tempComp->d){
                minWithinLabel = tempComp->d;
            }
        }
    }
    return minWithinLabel;
}
/* find reachable components in the same subgraph with the same label */
void findAllSameLabelSetExcess(component *curComp, llong minWithinLabel){
    // add all same label
    component *tmpComp;
    component *neiComp;
    candidateSet.insert(curComp);
    curComp->cNext = sentinel;
    sentinel->cNext = curComp;
    component** base;
    int startY;
    int endY;
    int *lowerBound;
    int *upperBound;
    int gID;
    int x00;
    int x11;
    int low;

    /* candidate add same-label */
    for(tmpComp = curComp;tmpComp!=sentinel;tmpComp=tmpComp->cNext){
        startY = tmpComp->startY;
        endY = tmpComp->endY;
        lowerBound = tmpComp->lowerBound;
        upperBound = tmpComp->upperBound;
        gID = tmpComp->gID;
        base = comLabels[gID];
        /* find within the same subgraph */
        /* lower side */
        for (int y=startY;y<endY;++y){
            x00 = lowerBound[y];
            low = lowGraphBound[gID][y];
            if(x00>low){
                neiComp = *(base + accumNumNode[gID][y] + x00 - 1 - low);
                if(minWithinLabel==neiComp->d && candidateSet.find(neiComp) == candidateSet.end()){
                    candidateSet.insert(neiComp);
                    queueAdd(neiComp);
                }
            }
        }
        /* right side */
        for (int y=startY;y<min(endY,T1-2);++y){
            low = lowGraphBound[gID][y+1];
            x00 = ceil(lowerBound[y]);
            x00 = max(x00,low>>2);
            x11 = min((y<endY-1?floor(lowerBound[y+1]):ceil(upperBound[endY-1])),ceil(upperBound[y]));
            base = comLabels[gID] + accumNumNode[gID][y+1] + 1 - low;
            for (int x=x00;x<x11;++x){
                neiComp = *(base + 2*x);
                if(minWithinLabel==neiComp->d && candidateSet.find(neiComp) == candidateSet.end()){
                    candidateSet.insert(neiComp);
                    queueAdd(neiComp);
                }
            }
        }
    }
    queueHead = curComp->cNext;
    candidateSet.clear();
}
/* find reachable components in the same subgraph with the same label */
void findAllSameLabelSetDeficit(component *curComp, llong minWithinLabel){
    // add all same label
    component *tmpComp;
    component *neiComp;
    candidateSet.insert(curComp);
    curComp->cNext = sentinel;
    sentinel->cNext = curComp;
    component** base;
    int startY;
    int endY;
    int *lowerBound;
    int *upperBound;
    int gID;
    int x00;
    int x11;
    int up;

    for(tmpComp = curComp;tmpComp!=sentinel;tmpComp=tmpComp->cNext){
        startY = tmpComp->startY;
        endY = tmpComp->endY;
        lowerBound = tmpComp->lowerBound;
        upperBound = tmpComp->upperBound;
        gID = tmpComp->gID;
        base = comLabels[gID];
        /* find within the same subgraph */
        /* upper side */
        for (int y=startY;y<endY;++y){
            x00 = upperBound[y];
            up = upGraphBound[gID][y];
            if(x00<up){
                neiComp = *(base + accumNumNode[gID][y] + x00 - lowGraphBound[gID][y]);
                if(minWithinLabel==neiComp->d && candidateSet.find(neiComp) == candidateSet.end()){
                    candidateSet.insert(neiComp);
                    queueAdd(neiComp);
                }
            }
        }
        /* left side */
        for (int y=max(startY,1);y<endY;++y){
            up = upGraphBound[gID][y-1];
            x00 = y>startY?ceil(upperBound[y-1]):floor(lowerBound[startY]);
            x11 = floor(upperBound[y]);
            x11 = min(x11,(up+1)>>1);
            base = comLabels[gID] + accumNumNode[gID][y-1] - lowGraphBound[gID][y-1];
            for (int x=x00;x<x11;++x){
                neiComp = *(base + x*2);
                if(minWithinLabel==neiComp->d && candidateSet.find(neiComp) == candidateSet.end()){
                    candidateSet.insert(neiComp);
                    queueAdd(neiComp);
                }
            }
        }
    }
    queueHead = curComp->cNext;
    candidateSet.clear();
}
/* re-label operation*/
void relabelExcess(component *curComp){
    llong minWithinLabel = totalNode;
    llong minCrossLabel = totalNode;
    curComp->cNext = sentinel;
    minCrossLabel = checkNeiLowestLabelExcess(curComp, minCrossLabel, curComp->d - 1);
    minWithinLabel = checkWithinLowestLabelExcess(curComp);

    while(minWithinLabel<=minCrossLabel){   /* push first. If merge first, minWithinLabel<=minCrossLabel+1 */
        if(minWithinLabel>=totalNode){
            curComp->d = totalNode;
            return ;
        }
        findAllSameLabelSetExcess(curComp, minWithinLabel);
        minCrossLabel = checkNeiLowestLabelExcess(queueHead, minCrossLabel, minWithinLabel - 2);   // find new min cross label
        merge(curComp);   /* mainly update comLabel and neighbor Relation */   
        minWithinLabel = checkWithinLowestLabelExcess(curComp);   // find new min within label
    }
    curComp->d = minCrossLabel+1;   // relabel
}
/* re-label operation*/
void relabelDeficit(component *curComp){
    llong minWithinLabel = totalNode;
    llong minCrossLabel = totalNode;
    curComp->cNext = sentinel;
    minCrossLabel = checkNeiLowestLabelDeficit(curComp, minCrossLabel, curComp->d - 1);
    minWithinLabel = checkWithinLowestLabelDeficit(curComp);

    while(minWithinLabel<=minCrossLabel){   /* push first. If merge first, minWithinLabel<=minCrossLabel+1 */
        if(minWithinLabel>=totalNode){
            curComp->d = totalNode;
            return ;
        }
        findAllSameLabelSetDeficit(curComp, minWithinLabel);
        minCrossLabel = checkNeiLowestLabelDeficit(queueHead, minCrossLabel, minWithinLabel - 2);   // find new min cross label
        merge(curComp);   /* mainly update comLabel and neighbor Relation */   
        minWithinLabel = checkWithinLowestLabelDeficit(curComp);   // find new min within label
    }
    curComp->d = minCrossLabel+1;   // relabel
}
/* discharge */
void dischargeExcess(component *curComp){
    int *lowerBound = curComp->lowerBound;
    int *upperBound = curComp->upperBound;
    int startY = curComp->startY;
    int endY = curComp->endY;
    int startX = floor(lowerBound[startY]);
    int endX = ceil(upperBound[endY-1]);
    int gID = curComp->gID;
    llong curLabel = curComp->d;
    int gID2;
    int pairID;
    int flowDir;
    int dir;
    int x0;
    int x1;
    int nextUpBound;
    int curLowBound;
    component *tempComp;
    capType currentCut;
    capType tmpUseCut;
    capType curPush;
    capType excess;
    capType pathCost;
    capType residualCap;
    capType tempExcess;
    /* update the active state for other components */
    bucket *l = buckets + curLabel - 1;
    int pos1;
    int pos2;
    capType* dist_ad;
    capType* inOutFlow_ad;
    capType* inOutFlow_ad2;
    capType* flow_ad;
    int nei_ad = gID*maxNeiNum;
    int low1;
    int low2;
    int up2;

    /* modify */
    /* source, sink modify according to in_out flow 
    link to source, add edges below
    link to sink, add edges above
    y: the edge between node y->y+1
    x: the edge between node x->x+1
    z: 0 is right edge, 1 is up+right inclined edge */
    
    if(!sameComp){
        for (int y = startY; y < endY; ++y){
            pos1 = y*colNode + lowerBound[y];
            pos2 = y*colNode + upperBound[y];
            inOutFlow_ad = inOutFlow[gID] + accumNumNode[gID][y] + upperBound[y] - lowGraphBound[gID][y];
            /* source part */
            sourceModify[pos2] = 0;
            for (int k = pos2-1; k >= pos1; --k){
                --inOutFlow_ad;
                sourceModify[k] = sourceModify[k+1] + max(0,-*inOutFlow_ad);
            }
            /* sink part */
            sinkModify[pos1] = 0;
            totalModify[pos1] = sourceModify[pos1];
            for (int k = pos1+1; k <= pos2; ++k){
                sinkModify[k] = sinkModify[k-1] + max(0,*inOutFlow_ad);
                ++inOutFlow_ad;
                totalModify[k] = sourceModify[k] + sinkModify[k];
            }
        }
    }

    /* Rmatrix: Dynamic programming */
    dist_ad = distMatrix[gID] + endY*T2;
    Rmatrix[endY][endX] = 0;
    /* The last column */
    for (int x = endX-1;x<<1 >=lowerBound[endY-1];--x){
        Rmatrix[endY][x] = Rmatrix[endY][x+1] + *(dist_ad + x + 1);
        revDirs[endY][x] = 1;
    }
    /* Other columns */
    for (int y = endY-1;y>=startY;--y){
        dist_ad = distMatrix[gID] + (y+1)*T2;
        x1 = floor(upperBound[y]);
        pos2 = y*colNode + upperBound[y];
        // x1 position
        if(x1<<1 != upperBound[y]){
            Cxy = Rmatrix[y+1][x1+1] + *(dist_ad+ x1 +1) + totalModify[pos2];
            --pos2;
        }else
            Cxy = CAP_MAX;

        if(x1<<1 >= lowerBound[y])
            Cy = Rmatrix[y+1][x1] + *(dist_ad+ x1) + totalModify[pos2];
        else
            Cy = CAP_MAX;

        minV = Cxy;
        dir = 2;
        if (AisNonLargerB(Cy,minV)){
            minV = Cy;
            dir = 3;
        }
        revDirs[y][x1] = dir;
        Rmatrix[y][x1] = minV;

        for (int x = x1-1; x>=ceil(lowerBound[y]); --x){
            /* up */
            Cx = Rmatrix[y][x+1] + *(dist_ad+x+1-T2);

            /* up + right */
            --pos2;
            Cxy = Rmatrix[y+1][x+1] + *(dist_ad+x+1) + totalModify[pos2];

            /* right */
            --pos2;
            Cy = Rmatrix[y+1][x] + *(dist_ad+x) + totalModify[pos2];
            
            /* get min value */
            minV = Cx;
            dir = 1;
            if (AisNonLargerB(Cxy,minV)){
                minV = Cxy;
                dir = 2;
            }
            if (AisNonLargerB(Cy,minV)){
                minV = Cy;
                dir = 3;
            }

            revDirs[y][x] = dir;
            Rmatrix[y][x] = minV;
        }

        x0 = floor(lowerBound[y]);
        if(x0<<1 != lowerBound[y] && lowerBound[y]<upperBound[y]){
            Cx = Rmatrix[y][x0+1] + *(dist_ad-T2+x0+1);
            --pos2;
            Cxy = Rmatrix[y+1][x0+1] + *(dist_ad+x0+1) + totalModify[pos2];
            minV = Cx;
            dir = 1;
            if (AisNonLargerB(Cxy,minV)){
                minV = Cxy;
                dir = 2;
            }
            revDirs[y][x0] = dir;
            Rmatrix[y][x0] = minV;
        }

        for(int x=x0-1;x>=(y>startY?ceil(lowerBound[y-1]):startX);--x){
            Rmatrix[y][x] = Rmatrix[y][x+1] + *(dist_ad-T2+x+1);
            revDirs[y][x] = 1;
        }
    }
    currentCut = Rmatrix[startY][startX];
    tmpUseCut = currentCut;
    
    /* find next bound */
    /* push by calculating DMatirx*/
    dist_ad = distMatrix[gID] + startY*T2;
    Dmatrix[startY][startX] = 0;
    x0 = startX;
    while(x0<T2-1 && revDirs[startY][x0]==1){
        ++x0;
        Dmatrix[startY][x0] = Dmatrix[startY][x0-1] + *(dist_ad+x0);
        dirs[startY][x0] = 1;
    }
    if(revDirs[startY][x0]==2)
        nextUpBound = (x0<<1) + 1;
    else
        nextUpBound = x0<<1;
    
    
    // other columns 
    for (int y = startY+1;y<=endY;++y){
        /* initialize */
        dist_ad = distMatrix[gID] + y*T2;
        curLowBound = lowerBound[y-1];
        pos2 = (y-1)*colNode + curLowBound;
        x0 = floor(curLowBound);
        pos1 = x0<<1;
        /* ------ bottom-up update minCut value below each node in this column ------*/
        // the bottom block
        // case z==0
        if(x0<<1 == curLowBound){
            pathCost = Dmatrix[y-1][x0] + Rmatrix[y][x0] + *(dist_ad+x0) + totalModify[pos2];
            minCutColumn[pos1] = pathCost;
            ++pos2;
        }else
            minCutColumn[pos1] = CAP_MAX;

        // case z = 1;
        if(nextUpBound>pos1){
            ++pos1;
            pathCost = Dmatrix[y-1][x0] + Rmatrix[y][x0+1] + *(dist_ad+x0+1) + totalModify[pos2];
            minCutColumn[pos1] = min(pathCost,minCutColumn[pos1-1]);
        }

        // middle blocks
        for (int x = x0+1;x<floor(nextUpBound-1);++x){
            // case z=0
            ++pos2;
            ++pos1;
            pathCost = Dmatrix[y-1][x] + Rmatrix[y][x] + *(dist_ad+x) + totalModify[pos2];
            minCutColumn[pos1] = min(minCutColumn[pos1-1],pathCost);
            // case z = 1;
            ++pos2;
            ++pos1;
            pathCost = Dmatrix[y-1][x] + Rmatrix[y][x+1] + *(dist_ad+x+1) + totalModify[pos2];
            minCutColumn[pos1] = min(pathCost,minCutColumn[pos1-1]);
        }

        // top block
        if(ceil(nextUpBound)>floor(curLowBound)+1){    // top block and bottom block are different
            x0 = (nextUpBound-1)>>1;
            ++pos2;
            ++pos1;
            // z==0
            pathCost = Dmatrix[y-1][x0] + Rmatrix[y][x0] + *(dist_ad+x0) + totalModify[pos2];
            minCutColumn[pos1] = min(minCutColumn[pos1-1],pathCost);
            // z==1
            if(nextUpBound == (x0+1)<<1){
                ++pos2;
                ++pos1;
                pathCost = Dmatrix[y-1][x0] + Rmatrix[y][x0+1] + *(dist_ad+x0+1) + totalModify[pos2];
                minCutColumn[pos1] = min(pathCost,minCutColumn[pos1-1]);
            }
        }
        /* ------ top-down push excess ------*/
        tmpUseCut = currentCut;
        if(winSize>T1-1||winSize>T2-1){
            inOutFlow_ad = inOutFlow[gID] + (y-1)*colNodeNum + pos1;
            for (;pos1>=curLowBound;--pos1,--inOutFlow_ad){
                pathCost = minCutColumn[pos1];
                for(int neiPos = 0;neiPos<addNeiCnt[gID];++neiPos){
                    excess = pathCost - currentCut; /* excess in current node */
                    if(excess<=0)                      /* no excess in this column */
                        break;
                    gID2 = gRelations[nei_ad+neiPos].gID2;
                    tempComp = comLabels[gID2][(y-1)*colNodeNum + pos1];
                    if(tempComp->d==curLabel-1){            /* lower label */
                        pairID = gRelations[nei_ad+neiPos].pairID;
                        flowDir = gRelations[nei_ad+neiPos].flowDir;
                        flow_ad = flow[pairID] + (y-1)*colNodeNum + pos1;
                        inOutFlow_ad2 = inOutFlow[gID2] + (y-1)*colNodeNum + pos1;
                        residualCap = neiCap[pairID] - flowDir*(*flow_ad);                   
                        curPush = min(excess,residualCap);
                        if(curPush>0){
                            /* update current cut */
                            currentCut += curPush;
                            /* update total graph */
                            *flow_ad += flowDir*curPush;
                            *inOutFlow_ad += curPush;
                            *inOutFlow_ad2 -= curPush;
                            /* record the components being pushed */
                            if(!tempComp->activeState){
                                tempComp->activeState=true;
                                iDelete(l,tempComp);
                                aAdd(l,tempComp);
                            }
                        }
                    }
                }
                if(pathCost<=currentCut)     // update new upperBound 
                    nextUpBound = pos1;
                pushedFlow[pos1] = currentCut - tmpUseCut;
                tmpUseCut = currentCut;
            }
        }else{
            low1 = lowGraphBound[gID][y-1];
            inOutFlow_ad = inOutFlow[gID] + accumNumNode[gID][y-1] + pos1 - low1;
            for (;pos1>=curLowBound;--pos1,--inOutFlow_ad){
                pathCost = minCutColumn[pos1];
                for(int neiPos = 0;neiPos<addNeiCnt[gID];++neiPos){
                    excess = pathCost - currentCut; /* excess in current node */
                    if(excess<=0)                      /* no excess in this column */
                        break;
                    gID2 = gRelations[nei_ad+neiPos].gID2;
                    up2 = upGraphBound[gID2][y-1];
                    low2 = lowGraphBound[gID2][y-1];
                    if(pos1>=up2 || pos1<low2)
                        continue;
                    pos2 = accumNumNode[gID2][y-1] + pos1 - low2;
                    tempComp = comLabels[gID2][pos2];
                    if(tempComp->d==curLabel-1){            /* lower label */
                        pairID = gRelations[nei_ad+neiPos].pairID;
                        flowDir = gRelations[nei_ad+neiPos].flowDir;
                        flow_ad = flow[pairID] + accumEdgeNum[pairID][y-1] + pos1 - max(low1,low2);
                        inOutFlow_ad2 = inOutFlow[gID2] + pos2;
                        residualCap = neiCap[pairID] - flowDir*(*flow_ad);                   
                        curPush = min(excess,residualCap);
                        if(curPush>0){
                            /* update current cut */
                            currentCut += curPush;
                            /* update total graph */
                            *flow_ad += flowDir*curPush;
                            *inOutFlow_ad += curPush;
                            *inOutFlow_ad2 -= curPush;
                            /* record the components being pushed */
                            if(!tempComp->activeState){
                                tempComp->activeState=true;
                                iDelete(l,tempComp);
                                aAdd(l,tempComp);
                            }
                        }
                    }
                }
                if(pathCost<=currentCut)     // update new upperBound 
                    nextUpBound = pos1;
                pushedFlow[pos1] = currentCut - tmpUseCut;
                tmpUseCut = currentCut;
            }
        }

        /* ------ bottom-up update modified edge and Dmatrix ------*/
        tempExcess = 0;
        ++pos1;
        pos2 = pos1 + (y-1)*colNode;
        // bottom block
        x0 = floor(curLowBound);
        if (x0<<1 == curLowBound){
            Dmatrix[y][x0] = Dmatrix[y-1][x0] + *(dist_ad+x0) + totalModify[pos2];
            dirs[y][x0] = 3;
        }else{
            /* up + right */
            Cxy = Dmatrix[y-1][x0] + *(dist_ad+x0+1) + totalModify[pos2];
            tempExcess += pushedFlow[pos1];
            /* right */
            if(nextUpBound>curLowBound){
                ++pos1;++pos2;
                totalModify[pos2] += tempExcess;
                Cy = Dmatrix[y-1][x0+1] + *(dist_ad+x0+1) + totalModify[pos2];
            }else
                Cy = CAP_MAX;

                /* get min */
            minV = Cy;
            dir = 3;
            if (AisNonLargerB(Cxy,minV)){
                minV = Cxy;
                dir = 2;
            }
            /* update */
            Dmatrix[y][x0+1] = minV;
            dirs[y][x0+1] = dir;                 
            ++x0;
        }

        // middle blocks
        for (int x = x0+1;x<=floor(nextUpBound);++x) {
            /* up */
            Cx = Dmatrix[y][x-1] + *(dist_ad+x);
            /* up + right */
            tempExcess += pushedFlow[pos1];
            ++pos1;++pos2;
            totalModify[pos2] += tempExcess;
            Cxy = Dmatrix[y-1][x-1] + *(dist_ad+x) + totalModify[pos2];
            /* right */
            tempExcess += pushedFlow[pos1];
            ++pos1;++pos2;
            totalModify[pos2] += tempExcess;
            Cy = Dmatrix[y-1][x] + *(dist_ad+x) + totalModify[pos2];

            /* get min */
            minV = Cy;
            dir = 3;
            if (AisNonLargerB(Cxy,minV)){
                minV = Cxy;
                dir = 2;
            }
            if (AisNonLargerB(Cx,minV)){
                minV = Cx;
                dir = 1;
            }
            /* update */
            Dmatrix[y][x] = minV;
            dirs[y][x] = dir;
        }
    
        // top block
        x0 = ceil(nextUpBound);
        if(x0<<1!=nextUpBound && nextUpBound>curLowBound){
            tempExcess += pushedFlow[pos1];
            ++pos1;++pos2;
            totalModify[pos2] += tempExcess;
            Cxy = Dmatrix[y-1][x0-1] + *(dist_ad+x0) + totalModify[pos2];
            Cx = Dmatrix[y][x0-1] + *(dist_ad+x0);
            /* get min */
            minV = Cxy;
            dir = 2;
            if (AisNonLargerB(Cx,minV)){
                minV = Cx;
                dir = 1;
            }
            /* update */
            Dmatrix[y][x0] = minV;
            dirs[y][x0] = dir;
        }

        // update nextBound
        while(x0<T2-1 && revDirs[y][x0]==1){
            ++x0;
            Dmatrix[y][x0] = Dmatrix[y][x0-1] + *(dist_ad+x0);
            dirs[y][x0] = 1;
        }
        if(revDirs[y][x0]==2)
            nextUpBound = (x0<<1) + 1;
        else
            nextUpBound = x0<<1;

    }
    // track temporal cut
    trackBack();
    statusChanged = currentCut>Rmatrix[startY][startX];
}
/* discharge */
void dischargeDeficit(component *curComp){
    int *lowerBound = curComp->lowerBound;
    int *upperBound = curComp->upperBound;
    int startY = curComp->startY;
    int endY = curComp->endY;
    int startX = floor(lowerBound[startY]);
    int endX = ceil(upperBound[endY-1]);
    int gID = curComp->gID;
    int gID2;
    int pairID;
    llong curLabel = curComp->d;
    int flowDir;
    int dir;
    int x0;
    int x1;
    int nextLowBound;
    int curUpBound;
    component *tempComp;
    capType currentCut;
    capType tmpUseCut;
    capType curPush;
    capType deficit;
    capType pathCost;
    capType residualCap;
    capType tempExcess;
    /* update the active state for other components */
    bucket *l = buckets + curLabel - 1;
    int pos1;
    int pos2;
    capType* dist_ad;
    capType* inOutFlow_ad;
    capType* inOutFlow_ad2;
    capType* flow_ad;
    int nei_ad = gID*maxNeiNum;
    int low1;
    int low2;
    int up2;

    /* modify */
    /* source, sink modify according to in_out flow 
    link to source, add edges below
    link to sink, add edges above
    y: the edge between node y->y+1
    x: the edge between node x->x+1
    z: 0 is right edge, 1 is up+right inclined edge */
    
    if(!sameComp){
        for (int y = startY; y < endY; ++y){
            pos1 = y*colNode + lowerBound[y];
            pos2 = y*colNode + upperBound[y];
            inOutFlow_ad = inOutFlow[gID] + accumNumNode[gID][y] + upperBound[y] - lowGraphBound[gID][y];
            /* source part */
            sourceModify[pos2] = 0;
            for (int k = pos2-1; k >= pos1; --k){
                --inOutFlow_ad;
                sourceModify[k] = sourceModify[k+1] + max(0,-*inOutFlow_ad);
            }
            /* sink part */
            sinkModify[pos1] = 0;
            totalModify[pos1] = sourceModify[pos1];
            for (int k = pos1+1; k <= pos2; ++k){
                sinkModify[k] = sinkModify[k-1] + max(0,*inOutFlow_ad);
                ++inOutFlow_ad;
                totalModify[k] = sourceModify[k] + sinkModify[k];
            }
        }
    }

    /* Dmatrix: Dynamic programming */
    dist_ad = distMatrix[gID] + startY*T2;
    Dmatrix[startY][startX] = 0;
    /* The first column */
    for (int x = startX+1; x <= floor(upperBound[startY]); ++x){
        Dmatrix[startY][x] = Dmatrix[startY][x-1] + *(dist_ad + x);
        dirs[startY][x] = 1;
    }
    
    /* Other columns */
    for (int y = startY+1; y <= endY; ++y){
        dist_ad = distMatrix[gID] + y*T2;
        x0 = ceil(lowerBound[y-1]);
        pos2 = (y-1)*colNode + lowerBound[y-1];
        if(x0 != floor(lowerBound[y-1])){
            Cxy = Dmatrix[y-1][x0-1] + *(dist_ad+x0) + totalModify[pos2];
            ++pos2;
        }else
            Cxy = CAP_MAX;

        if(x0 <= floor(upperBound[y-1])){
            Cy = Dmatrix[y-1][x0] + *(dist_ad+x0) + totalModify[pos2];
        }else
            Cy = CAP_MAX;

        minV = Cy;
        dir = 3;
        if (AisNonLargerB(Cxy,minV)){
            minV = Cxy;
            dir = 2;
        }
        Dmatrix[y][x0] = minV;
        dirs[y][x0] = dir;

        for (int x = x0+1; x<=floor(upperBound[y-1]); ++x) {
            /* up */
            Cx = Dmatrix[y][x-1] + *(dist_ad+x);          
            /* up+right */
            ++pos2;
            Cxy = Dmatrix[y-1][x-1] + *(dist_ad+x) + totalModify[pos2];
            /* right */
            ++pos2;
            Cy = Dmatrix[y-1][x] + *(dist_ad+x) + totalModify[pos2];
            /* get min */
            minV = Cy;
            dir = 3;
            if (AisNonLargerB(Cxy,minV)){
                minV = Cxy;
                dir = 2;
            }
            if (AisNonLargerB(Cx,minV)){
                minV = Cx;
                dir = 1;
            }
            
            /* update */
            Dmatrix[y][x] = minV;
            dirs[y][x] = dir;
        }

        x0 = ceil(upperBound[y-1]);
        if(x0<<1 != upperBound[y-1] && upperBound[y-1]>lowerBound[y-1]){   // not the same block
            Cx = Dmatrix[y][x0-1] + *(dist_ad+x0);
            ++pos2;
            Cxy = Dmatrix[y-1][x0-1] + *(dist_ad+x0) + totalModify[pos2];
            /* get min */
            minV = Cxy;
            dir = 2;
            if (AisNonLargerB(Cx,minV)){
                minV = Cx;
                dir = 1;
            }
            /* update */
            Dmatrix[y][x0] = minV;
            dirs[y][x0] = dir;
        }

        x1 = y<endY?floor(upperBound[y]):endX;
        for(int x=x0+1;x<=x1;++x){
            Dmatrix[y][x] = Dmatrix[y][x-1] + *(dist_ad+x);
            dirs[y][x] = 1;
        }
    }
    currentCut = Dmatrix[endY][endX];
    tmpUseCut = currentCut;
    
    /* Rmatrix */
    /* find next bound */
    /* push by calculating DMatirx*/
    dist_ad = distMatrix[gID] + endY*T2;
    Rmatrix[endY][endX] = 0;
    for (int x = endX-1;x<<1 >=lowerBound[endY-1];--x){
        Rmatrix[endY][x] = Rmatrix[endY][x+1] + *(dist_ad+x+1);
        revDirs[endY][x] = 1;
    }
    x0 = endX;
    while(dirs[endY][x0]==1)
        --x0;
    if(dirs[endY][x0]==2)
        nextLowBound = (x0<<1) - 1;
    else
        nextLowBound = x0<<1;
    
    // other columns 
    for (int y = endY-1;y>=startY;--y){
        /* initialize */
        dist_ad = distMatrix[gID] + (y+1)*T2;
        curUpBound = upperBound[y];
        pos2 = y*colNode + curUpBound;
        x0 = floor(curUpBound);
        pos1 = (x0<<1)+1;

        /* ------ top-down update minCut value above each node ------*/
        // the top block
        // case z = 1;
        if(x0<<1 != curUpBound){
            pathCost = Dmatrix[y][x0] + Rmatrix[y+1][x0+1] + *(dist_ad+x0+1) + totalModify[pos2];
            minCutColumn[pos1] = pathCost;
            --pos2;
        }else
            minCutColumn[pos1] = CAP_MAX;

        // case z==0
        if(x0<<1 > nextLowBound){
            --pos1;
            pathCost = Dmatrix[y][x0]+ Rmatrix[y+1][x0] + *(dist_ad+x0) + totalModify[pos2];
            minCutColumn[pos1] = min(minCutColumn[pos1+1],pathCost);
        }

        // middle blocks
        for (int x = x0-1;x<<1 > nextLowBound;--x){
            // case z = 1;
            --pos2;
            --pos1;
            pathCost = Dmatrix[y][x] + Rmatrix[y+1][x+1] + *(dist_ad+x+1) + totalModify[pos2];
            minCutColumn[pos1] = min(pathCost,minCutColumn[pos1+1]);

            // case z=0
            --pos2;
            --pos1;
            pathCost = Dmatrix[y][x] + Rmatrix[y+1][x] + *(dist_ad+x) + totalModify[pos2];
            minCutColumn[pos1] = min(minCutColumn[pos1+1],pathCost);
        }

        // bottom block
        if(floor(curUpBound)>floor(nextLowBound)){    // top block and bottom block are different
            x0 = floor(nextLowBound);
            // z==1
            if(nextLowBound==x0<<1){
                --pos2;
                --pos1;
                pathCost = Dmatrix[y][x0] + Rmatrix[y+1][x0+1] + *(dist_ad+x0+1) + totalModify[pos2];
                minCutColumn[pos1] = min(pathCost,minCutColumn[pos1+1]);
            }
            // z==0, no need. 
        }
        
        /* ---------- bottom-up push deficit ------------ */
        tmpUseCut = currentCut;
        if(winSize>T1-1||winSize>T2-1){
            inOutFlow_ad = inOutFlow[gID] + y*colNodeNum + pos1 - 1;
            for (;pos1<=curUpBound;++pos1,++inOutFlow_ad){
                pathCost = minCutColumn[pos1];
                for(int neiPos = 0;neiPos<addNeiCnt[gID];++neiPos){
                    deficit = pathCost - currentCut; /* excess in current node */
                    if(deficit<=0)                     /* no excess in this column */
                        break;
                    gID2 = gRelations[nei_ad+neiPos].gID2;
                    tempComp = comLabels[gID2][y*colNodeNum + pos1 - 1];   /* neighbor component */
                    if(tempComp->d==curLabel-1){            /* lower label */
                        pairID = gRelations[nei_ad+neiPos].pairID;
                        flowDir = gRelations[nei_ad+neiPos].flowDir;
                        flow_ad = flow[pairID] + y*colNodeNum + pos1 - 1;
                        inOutFlow_ad2 = inOutFlow[gID2] + y*colNodeNum + pos1 - 1;
                        residualCap = neiCap[pairID] + flowDir*(*flow_ad);                   
                        curPush = min(deficit,residualCap);
                        if(curPush>0){
                            /* update current cut */
                            currentCut += curPush;
                            /* update total graph */
                            *flow_ad -= flowDir*curPush;
                            *inOutFlow_ad -= curPush;
                            *inOutFlow_ad2 += curPush;
                            /* record the components being pushed */
                            if(!tempComp->activeState){
                                tempComp->activeState=true;
                                iDelete(l,tempComp);
                                aAdd(l,tempComp);
                            }
                        }
                    }
                }
                if(pathCost<=currentCut)     // update new upperBound 
                    nextLowBound = pos1;
                pushedFlow[pos1-1] = currentCut - tmpUseCut;
                tmpUseCut = currentCut;
            }
        }else{
            low1 = lowGraphBound[gID][y];
            inOutFlow_ad = inOutFlow[gID] + accumNumNode[gID][y] + pos1 - 1 - low1;
            for (;pos1<=curUpBound;++pos1,++inOutFlow_ad){
                pathCost = minCutColumn[pos1];
                for(int neiPos = 0;neiPos<addNeiCnt[gID];++neiPos){
                    deficit = pathCost - currentCut; /* excess in current node */
                    if(deficit<=0)                     /* no excess in this column */
                        break;
                    gID2 = gRelations[nei_ad+neiPos].gID2;
                    up2 = upGraphBound[gID2][y];
                    low2 = lowGraphBound[gID2][y];
                    if(pos1>up2 || pos1<=low2)
                        continue;
                    pos2 = accumNumNode[gID2][y] + pos1 - 1 - low2;
                    tempComp = comLabels[gID2][pos2];   /* neighbor component */
                    if(tempComp->d==curLabel-1){            /* lower label */
                        pairID = gRelations[nei_ad+neiPos].pairID;
                        flowDir = gRelations[nei_ad+neiPos].flowDir;
                        flow_ad = flow[pairID] + accumEdgeNum[pairID][y] + pos1 - 1 - max(low1,low2);
                        inOutFlow_ad2 = inOutFlow[gID2] + pos2;
                        residualCap = neiCap[pairID] + flowDir*(*flow_ad);                   
                        curPush = min(deficit,residualCap);
                        if(curPush>0){
                            /* update current cut */
                            currentCut += curPush;
                            /* update total graph */
                            *flow_ad -= flowDir*curPush;
                            *inOutFlow_ad -= curPush;
                            *inOutFlow_ad2 += curPush;
                            /* record the components being pushed */
                            if(!tempComp->activeState){
                                tempComp->activeState=true;
                                iDelete(l,tempComp);
                                aAdd(l,tempComp);
                            }
                        }
                    }
                }
                if(pathCost<=currentCut)     // update new upperBound 
                    nextLowBound = pos1;
                pushedFlow[pos1-1] = currentCut - tmpUseCut;
                tmpUseCut = currentCut;
            }
        }

        /* ---------- top-down update modified edge and Rmatrix ------------ */
        tempExcess = 0;
        pos1 = curUpBound;
        pos2 = pos1 + y*colNode;
        // top block
        x0 = floor(curUpBound);
        if(x0<<1 == curUpBound){
            Rmatrix[y][x0] = Rmatrix[y+1][x0] + *(dist_ad+x0) + totalModify[pos2];
            revDirs[y][x0] = 3;
        }else{
            Cxy = Rmatrix[y+1][x0+1] + *(dist_ad+x0+1) + totalModify[pos2];
            if(curUpBound>nextLowBound){
                --pos1;--pos2;
                tempExcess += pushedFlow[pos1];
                totalModify[pos2] += tempExcess;
                Cy = Rmatrix[y+1][x0] + *(dist_ad+x0) + totalModify[pos2];
            }else{
                Cy = CAP_MAX;
            }

            minV = Cy;
            dir = 3;
            if (AisNonLargerB(Cxy,minV)){
                minV = Cxy;
                dir = 2;
            }
            Rmatrix[y][x0] = minV;
            revDirs[y][x0] = dir;
        }

        // middle blocks
        for(int x = x0-1;x>=ceil(nextLowBound);--x){
            Cx = Rmatrix[y][x+1] + *(dist_ad+x+1-T2);
            --pos1;--pos2;
            tempExcess += pushedFlow[pos1];
            totalModify[pos2] += tempExcess;
            Cxy = Rmatrix[y+1][x+1] + *(dist_ad+x+1) + totalModify[pos2];
            --pos1;--pos2;
            tempExcess += pushedFlow[pos1];
            totalModify[pos2] += tempExcess;
            Cy = Rmatrix[y+1][x] + *(dist_ad+x) + totalModify[pos2];

            minV = Cy;
            dir = 3;
            if (AisNonLargerB(Cxy,minV)){
                minV = Cxy;
                dir = 2;
            }
            if (AisNonLargerB(Cx,minV)){
                minV = Cx;
                dir = 1;
            }
            Rmatrix[y][x] = minV;
            revDirs[y][x] = dir;
        }

        // bottom block
        x0 = floor(nextLowBound);
        if(x0<<1 != nextLowBound && curUpBound>nextLowBound){
            Cx = Rmatrix[y][x0+1] + *(dist_ad+x0+1-T2);
            --pos1;--pos2;
            tempExcess += pushedFlow[pos1];
            totalModify[pos2] += tempExcess;
            Cxy = Rmatrix[y+1][x0+1] + *(dist_ad+x0+1) + totalModify[pos2];
            minV = Cxy;
            dir = 2;
            if (AisNonLargerB(Cx,minV)){
                minV = Cx;
                dir = 1;
            }
            Rmatrix[y][x0] = minV;
            revDirs[y][x0] = dir;
        }
        
        // update nextBound
        while(x0>0 && dirs[y][x0]==1){
            --x0;
            Rmatrix[y][x0] = Rmatrix[y][x0+1] + *(dist_ad+x0+1-T2);
            revDirs[y][x0] = 1;
        }
        if(dirs[y][x0]==2)
            nextLowBound = (x0<<1) - 1;
        else
            nextLowBound = x0<<1;
    }
    // track temporal cut
    revTrackBack();
    statusChanged = currentCut>Dmatrix[endY][endX];
}
/* push to neighbor subgraph + relabel */
void pushCrossExcess(component *curComp){
    /* ----------- push -------------- */
    llong orgLabel = curComp->d;
    bucket *l = buckets + orgLabel;
    aRemove(l,curComp);
    dischargeExcess(curComp);
    updateCrossPushExcess(curComp);
    /* ------------ relabel ---------------*/
    if(curComp->activeState){   
        aRemove(l,curComp);
        relabelExcess(curComp); /* relabel. Relabel could be in the same label */
        /* check gap after relabel*/
        if(curComp->d!=orgLabel && l->firstActive==sentinel && l->firstInactive ==sentinel){
            /* clear current component */
            curComp->d = totalNode;
            clearComp(curComp);
            stackAdd(clearHead,curComp);  
            /* clear bucket */
            gap(l);
            return;
        }
        /* the case no cross neighbor and cannot push out */
        if(curComp->d>=totalNode){  /* sink side */
            curComp->d = totalNode;
            clearComp(curComp);
            stackAdd(clearHead,curComp);
            return;
        }
        bucketMaintain(curComp->d);
        aAdd((buckets + curComp->d),curComp);
    }
}
/* push to neighbor subgraph + relabel */
void pushCrossDeficit(component *curComp){
    /* ----------- push -------------- */
    llong orgLabel = curComp->d;
    bucket *l = buckets + orgLabel;
    aRemove(l,curComp);
    dischargeDeficit(curComp);
    updateCrossPushDeficit(curComp);
    /* ------------ relabel ---------------*/
    if(curComp->activeState){
        aRemove(l,curComp);
        relabelDeficit(curComp); /* relabel. Relabel could be in the same label */
        /* check gap after relabel*/
        if(curComp->d!=orgLabel && l->firstActive==sentinel && l->firstInactive ==sentinel){    // find gap
            /* clear current component */
            curComp->d = totalNode;
            clearComp(curComp);
            stackAdd(clearHead,curComp);  
            /* clear bucket */
            gap(l);
            return;
        }
        /* the case no cross neighbor and cannot push out */
        if(curComp->d>=totalNode){  /* sink side */
            curComp->d = totalNode;
            clearComp(curComp);
            stackAdd(clearHead,curComp);
            return;
        }
        bucketMaintain(curComp->d);
        aAdd((buckets + curComp->d),curComp);
    }
}
/* delete the components will never use anymore */
void clearStageOne(){
    component *tmpComp;
    component *nextComp;
    for(tmpComp = clearHead;tmpComp!=sentinel;tmpComp=nextComp){
        nextComp = tmpComp->cNext;
        delete tmpComp;
    }
    clearHead = sentinel;
}
/* release memory */
void release(){
    bucket *l;
    component *tmpComp;
    component *nextComp;

    for(tmpComp = clearHead;tmpComp!=sentinel;tmpComp=nextComp){
        nextComp = tmpComp->cNext;
        delete tmpComp;
    }

    for (l = buckets;l<=(buckets+dMax);++l){
        for(tmpComp = l->firstInactive;tmpComp!=sentinel;tmpComp=nextComp){
            nextComp = tmpComp->bNext;
            clearComp(tmpComp);
            delete tmpComp;
        }
    }

    delete sentinel;
    delete[] buckets;
    delete[] tempCut;
    for (int i=0;i<T1;++i){
        delete[] Dmatrix[i];
        delete[] dirs[i];
        delete[] Rmatrix[i];
        delete[] revDirs[i];
    }
    delete[] Dmatrix;
    delete[] Rmatrix;
    delete[] dirs;
    delete[] revDirs;
    delete[] initialCut;
    delete[] neiCap;

    for(int gID = 0;gID<N;++gID){
        delete[] distMatrix[gID];
        delete[] comLabels[gID];
        delete[] inOutFlow[gID];
        delete[] accumNumNode[gID];
        delete[] lowGraphBound[gID];
        delete[] upGraphBound[gID];
    }
    delete[] distMatrix;
    delete[] comLabels;
    delete[] inOutFlow;
    delete[] accumNumNode;
    delete[] lowGraphBound;
    delete[] upGraphBound;

    for(int pairID = 0;pairID<nPair;++pairID){
        delete[] flow[pairID];
        delete[] accumEdgeNum[pairID];
    }
    delete[] flow;
    delete[] accumEdgeNum;
    
    delete[] sourceModify;
    delete[] sinkModify;
    delete[] totalModify;
    delete[] Gij;
    delete[] minCutColumn;
    delete[] pushedFlow;
    delete[] gRelations;
    delete[] addNeiCnt;
}
/* stage one: push excess */
void stageOne(){
    bucket *l;                      /* current bucket */
    component *curComp;             /* current component */
    component *preComp = sentinel;
    while(aMax >= aMin){
        l = buckets + aMax;         /* highest label */
        curComp = l->firstActive;
        if(curComp==sentinel)
            --aMax;
        else{
            ++deBugCnt;
            if(aMax==0){    // within push
                aRemove(buckets,curComp);
                pushWithinGraphExcess(curComp); /* ---- need to code the state 1 */
                updateWithinPushExcess(curComp);
                preComp = sentinel;
            }else{
                sameComp = noMerge & curComp==preComp;
                /* avoid dead loop, may occur due to resolution*/
                if(sameComp && preLabel == aMax && (!statusChanged)){
                    aRemove(l,curComp);
                    curComp->activeState = false;
                    iAdd(l,curComp);
                    continue;
                }
                preLabel = aMax;
                statusChanged = false;
                noMerge = true;
                pushCrossExcess(curComp);
                preComp = curComp;
            }
        }
    }
}
/* stage two: push deficit */
void stageTwo(){
    bucket *l;                      /* current bucket */
    component *curComp;             /* current component */
    component *preComp = sentinel;
    while(aMax >= aMin){
        l = buckets + aMax;         /* highest label */
        curComp = l->firstActive;
        if(curComp==sentinel)
            --aMax;
        else{
             ++deBugCnt;
            if(aMax==0){
                // within push
                aRemove(buckets,curComp);
                pushWithinGraphDeficit(curComp); /* ---- need to code the state 1 */
                updateWithinPushDeficit(curComp);
                preComp = sentinel;
            }else{
                sameComp = noMerge & curComp==preComp;
                /* avoid dead loop, may occur due to resolution*/
                if(sameComp && preLabel == aMax && (!statusChanged)){
                    aRemove(l,curComp);
                    curComp->activeState = false;
                    iAdd(l,curComp);
                    continue;
                }
                preLabel = aMax;
                statusChanged = false;
                noMerge = true;
                pushCrossDeficit(curComp);
                preComp = curComp;
            }            
        }
    }
}
/* get min-cut of push excess */
void minCut_up(){
    // initialization 
    for (int gID=0;gID<N;gID++){
        for (int y=0;y<tempT1;++y){
            initialCut[gID*tempT1+y] = upGraphBound[gID][y];
        }
    }

    bucket *l;
    component *tmpComp;
    int startY;
    int endY;
    int gID;
    int* lowerBound;

    for (l = buckets;l<=(buckets+dMax);++l){
        for(tmpComp = l->firstInactive;tmpComp!=sentinel;tmpComp=tmpComp->bNext){
            startY = tmpComp->startY;
            endY = tmpComp->endY;
            gID = tmpComp->gID;
            lowerBound = tmpComp->lowerBound;
            for (int y = startY; y < endY; ++y)
                initialCut[gID*tempT1+y] = min(initialCut[gID*tempT1+y],lowerBound[y]);
        }
    }
}
/* get min-cut of push deficit */
void minCut_low(){
    // initialization 
    for (int gID=0;gID<N;gID++){
        for (int y=0;y<tempT1;++y){
            initialCut[gID*tempT1+y] = lowGraphBound[gID][y];
        }
    }

    bucket *l;
    component *tmpComp;
    int startY;
    int endY;
    int gID;
    int* upperBound;

    for (l = buckets;l<=(buckets+dMax);++l){
        for(tmpComp = l->firstInactive;tmpComp!=sentinel;tmpComp=tmpComp->bNext){
            startY = tmpComp->startY;
            endY = tmpComp->endY;
            gID = tmpComp->gID;
            upperBound = tmpComp->upperBound;
            for (int y = startY; y < endY; ++y)
                initialCut[gID*tempT1+y] = max(initialCut[gID*tempT1+y],upperBound[y]);
        }
    }
}

/* enlarge graph bound */
void enlarge(int* initialCut,int winSize){
    lowGraphBound = new int*[N];
    upGraphBound = new int*[N];
    int height = 2*(T2-1);
    if(winSize>min(T1,T2)-1){
        for(int gID = 0;gID<N;gID++){
            lowGraphBound[gID] = new int[tempT1]();
            upGraphBound[gID] = new int[tempT1];
            for(int y=0;y<tempT1;y++)
                upGraphBound[gID][y] = height;
        }
        return;
    }
    int tempValue;
    int preValue;
    int tempValue2;
    for(int gID = 0;gID<N; gID++){
        lowGraphBound[gID] = new int[tempT1];
        upGraphBound[gID] = new int[tempT1];
        for(int y=0;y<tempT1;y++){
            tempValue = initialCut[gID*tempT1 + y];
            lowGraphBound[gID][y] = max(0,tempValue-winSize*2);
            upGraphBound[gID][y] = min(height,tempValue+winSize*2);
        }
        for(int y=0;y<tempT1;y++){
            tempValue = initialCut[gID*tempT1 + y];
            if(y>=winSize)
                upGraphBound[gID][y-winSize] = max(upGraphBound[gID][y-winSize],tempValue);

            if(y<tempT1-winSize)
                lowGraphBound[gID][y+winSize] = min(lowGraphBound[gID][y+winSize],tempValue);
        }
        for(int k=0;k<min(tempT1,winSize);k++){
            upGraphBound[gID][tempT1-1-k] = height;
            lowGraphBound[gID][k] = 0;
        }
        // special points
        preValue = ceil(initialCut[gID*tempT1]);
        for(int y=1;y<tempT1;y++){
            tempValue = initialCut[gID*tempT1 + y];
            if(floor(tempValue)>preValue){
                tempValue2 = (preValue-winSize)*2+1;
                for(int add = 0;add<min(tempT1-y,winSize);add++){
                    lowGraphBound[gID][y+add] = min(lowGraphBound[gID][y+add],max(0,tempValue2));
                    tempValue2 +=2;
                }
                tempValue2 = ((tempValue>>1) +winSize)*2-1;
                for(int add = 0;add<min(y,winSize);add++){
                    upGraphBound[gID][y-add-1] = max(upGraphBound[gID][y-add-1],min(height,tempValue2));
                    tempValue2 -=2;
                }
            }
            preValue = ceil(tempValue);
        }
    }
}


#ifndef DEBUG
/* get final min-cut */
void getMinCut(double *minCut,double *maxFlow){
    // initialization 
    int curCut;
    int preHeight;
    
    for (int y = 0;y<tempT1; ++y){
        for(int gID=0; gID<N; ++gID){
            curCut = initialCut[gID*tempT1+y];
            preHeight = curCut>>1;
            minCut[y*N + gID] = preHeight<<1 == curCut?preHeight:preHeight+0.5;
        }
    }
    
    // calculate max flow value 
    double value = 0;
    double curHeight;
    for (int gID = 0;gID<N;++gID){
        int preHeight = 0;
        // first T1-1 columns 
        for (int y = 0;y<tempT1;++y){
            double curHeight = minCut[y*N + gID];
            for(int x=preHeight;x<=curHeight;++x){
                value = value + distMatrix[gID][y*T2 + x];
            }
            preHeight = curHeight+0.5;
        }
        // last column 
        for(int x=preHeight;x<=T2-1;++x){
            value = value + distMatrix[gID][tempT1*T2 + x];
        }
        value = value - distMatrix[gID][0];
    }
    for (int pairID=0;pairID<nPair;++pairID){
        int gID1 = Gij[pairID*2];
        int gID2 = Gij[pairID*2+1];
        for (int y = 0; y < tempT1; ++y)
            value = value + abs((minCut[y*N + gID1]-minCut[y*N + gID2]))*2*neiCap[pairID];
    }

    #ifdef CAP_TYPE_LONG
        maxFlow[0] = value/ROUNDSCALE;
    #else
        maxFlow[0] = value;
    #endif
}
/* load variables from input */
void mexload(double *ref, double *tst, double *GijTemp, bool metric){
    // distMatrix 
    distMatrix = new capType*[N];
    for(int gID = 0;gID<N;gID++){
        distMatrix[gID] = new capType[T1*T2];
    }
    capType* capType_ad;
    float dif;
    capType minCap = FLT_MAX;

    // distMatrix: gID*T1*T2 + y*T2 + x
    // ref: y*N + gID
    // tst: x*N + gID  
    for (int gID = 0; gID < N; ++gID){
        capType_ad = distMatrix[gID];
        for (int y = 0; y < T1; ++y) {
            for (int x = 0; x < T2; ++x) {
                dif = ref[gID + y*N] - tst[gID + x*N];
                *capType_ad = metric?dif*dif:(dif>0?dif:-dif);
                ++capType_ad;
            }
        }
    }
    neiCap = new capType[nPair];
    for (int pairID = 0; pairID < nPair; ++pairID){
        neiCap[pairID] = GijTemp[pairID + 2*nPair];
        minCap = min(neiCap[pairID],minCap);
    }

    MATLAB_ASSERT(minCap>=0, "BILCOMex: Hyperparameter smo is not nonnegative");

    // Gij: pairID*2 + 0/1
    Gij = new int[nPair*2];
    capType gID1;
    capType gID2;
    int* int_ad = Gij;
    for (int pairID = 0; pairID < nPair; ++pairID) {
        gID1 = GijTemp[pairID] - 1;
        gID2 = GijTemp[pairID+1*nPair] - 1;
        MATLAB_ASSERT(isInteger(gID1) && isInteger(gID2), "BILCOMex: Graph ID is not integer");
        MATLAB_ASSERT(gID1>=0 && gID1>=0 && gID1<N && gID2<N, "BILCOMex: Graph ID is out of range [1,N]");
        *int_ad = gID1;
        ++int_ad;
        *int_ad = gID2;
        ++int_ad;
    }
}

void loadInitialCut(double *InitialCutTemp){
    capType cut;
    initialCut = new int[N*tempT1];
    int* int_ad = initialCut;
    for(int gID=0;gID<N;++gID){
        for(int t=0;t<tempT1;++t){
            cut = (InitialCutTemp[gID + t*N] - 1)*2;
            MATLAB_ASSERT(isInteger(cut) && cut>=0 && cut<=2*(T2-1), "BILCOMex: error in initial cut: expect each element represents the height of path between [1,T2], decimal places are 0.5 or 0");
            *int_ad = cut;
            ++int_ad;
        }
    }
}

/* main function */
void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[]) {
    // ref, tst, Gij, initialCut, winSize, metric
    
    MATLAB_ASSERT(nrhs>=3 & nrhs<=6, "BILCOMex: Wrong number of input parameters: expected 3-6");

    N = mxGetM(prhs[1]);
    T1 = mxGetN(prhs[0]);
    tempT1 = T1 - 1;
    T2 = mxGetN(prhs[1]);
    nPair = mxGetM(prhs[2]);

    MATLAB_ASSERT(T1>1 && T2>1, "BILCOMex: The input parameters are not correctly formatted: expect ref: NxT1 tst: NxT2. T1 and T2 should be larger than 1");
    MATLAB_ASSERT(mxGetM(prhs[0])==N, "BILCOMex: The input parameters are not correctly formatted: expect ref: NxT1, tst: NxT2");
    MATLAB_ASSERT(mxGetPi(prhs[0]) == NULL && mxGetPi(prhs[1])==NULL && mxGetPi(prhs[2])==NULL, "BILCOMex: Unary potentials should not be complex");
    
    /* if initial cut */
    if(nrhs>=4){
        MATLAB_ASSERT(mxGetM(prhs[3])==N && mxGetN(prhs[3])==T1-1, "BILCOMex: Initial cut is not correctly formatted: expect Nx(T1-1) array");
        loadInitialCut(mxGetPr(prhs[3]));
    }else{
        initialCut = new int[N*tempT1]();
    }

    if(nrhs>=5){
        MATLAB_ASSERT(mxGetM(prhs[4])==1 && mxGetN(prhs[4])==1, "BILCOMex: WinSize parameter should be one integer");
        winSize = *mxGetPr(prhs[4]);
        enlarge(initialCut,winSize);
    }else{
        lowGraphBound = new int*[N];
        upGraphBound = new int*[N];
        for(int gID = 0;gID<N;gID++){
            lowGraphBound[gID] = new int[tempT1]();
            upGraphBound[gID] = new int[tempT1];
            for(int y=0;y<T1;y++)
                upGraphBound[gID][y] = 2*T2-2;
        }
    }

    bool metric = true; // true: use squared difference as measure, false: use absolute difference as measure
    string str1("squared");
    string str2("absolute");
    if(nrhs==6){
        if(!str1.compare(mxArrayToString(prhs[5])))
            metric = true;
        else if(!str2.compare(mxArrayToString(prhs[5])))
            metric = false;
        else
            MATLAB_ASSERT(false, "Wrong metric");
    }

    /* load */
    mexload(mxGetPr(prhs[0]), mxGetPr(prhs[1]), mxGetPr(prhs[2]), metric);

    /* allocate memory */    
    allocDS();

    /* ----------------- main algorithm -------------------- */
    /* push excess above initial cut */
    init_StageOne();
    stageOne();
    minCut_up();
    clearStageOne();
    /* push deficit below new cut */
    init_StageTwo();
    stageTwo();
    minCut_low();

    /* get final min-cut and max-flow */
    plhs[0] = mxCreateDoubleMatrix(N, tempT1, mxREAL);
    double *outArray = mxGetPr(plhs[0]);
    plhs[1] = mxCreateDoubleMatrix(1, 1, mxREAL);
    double *maxFlow = mxGetPr(plhs[1]);
    getMinCut(outArray,maxFlow);
    /* release memory */
    release();
    
    return;
}
#else
int loadInput(char filename[]) {
#define MAXLINE 100	            // max line length in the input file 
#define P_FIELDS 3              // no of fields in problem line 

    // temporal variable 
    capType** ref = NULL;                  // reference array 
    capType** tst = NULL;                  // test array 
    int gID;                        // subgraph ID 
    int pos;                        // position 
    float value;                    // value 
    int id1, id2;                   // gID 
    int cntPair = 0;                // count current pair 
    float dif;                      // dif
    int winSize;

    char in_line[MAXLINE];          // for reading input line 
    FILE* fp;
    fp = fopen(filename, "r");
    if (NULL == fp)
    {
        printf("File open error!\n");
    }

    while (fgets(in_line, MAXLINE, fp) != NULL)
    {
        switch (in_line[0])
        {
        case '\n': // skip empty lines   
        case '\0':  // skip empty lines at the end of file 
            printf("\n");
            break;

        case 'p': // problem description      *

            if (
                // reading problem line: type of problem, no of nodes, no of arcs 
                sscanf(in_line, "%*c %d %d %d %d %d", &N, &T1, &T2, &nPair, &winSize) != P_FIELDS)
                // wrong number of parameters in the problem line

            if (N <= 0 || T1 <= 0 || nPair < 0)
                // wrong value of no of arcs or nodes
            {
                printf("Wrong input problem!\n");
            }

            // allocating memory for  'Gij', 'ref', 'tst',  and 'neiCap' 
            // Gij 
            // ref, tst 
            ref = new capType * [T1];
            tst = new capType * [T2];
            tempT1 = T1-1;
            for (int i = 0; i < T1; i++) 
                ref[i] = new capType[N];

            for (int i = 0; i < T2; i++)
                tst[i] = new capType[N];

            // neiCap 
            Gij = new int[nPair*2];
            neiCap = new capType[nPair];
            initialCut = new int[N*tempT1];
            break;
        case 'r': // problem description      

            if (
                // reading problem line: type of problem, no of nodes, no of arcs 
                sscanf(in_line, "%*c %d %d %f", &pos, &gID, &value) != P_FIELDS)
                // wrong number of parameters in the problem line
            {
                printf("Wrong input format!\n");
            }

            if (pos <= 0 || gID <= 0)
                // wrong value of no of arcs or nodes
            {
                printf("Wrong input problem!\n");
            }

            // assign value 
            ref[pos - 1][gID - 1] = value;
            break;
        case 't': // problem description      

            if (
                // reading problem line: type of problem, no of nodes, no of arcs 
                sscanf(in_line, "%*c %d %d %f", &pos, &gID, &value) != P_FIELDS)
                // wrong number of parameters in the problem line
            {
                printf("Wrong input format!\n");
            }

            if (pos <= 0 || gID <= 0)
                // wrong value of no of arcs or nodes
            {
                printf("Wrong input problem!\n");
            }

            // assign value 
            tst[pos - 1][gID - 1] = value;
            break;
        case 'g': // problem description      

            if (
                // reading problem line: type of problem, no of nodes, no of arcs 
                sscanf(in_line, "%*c %d %d %f", &id1, &id2, &value) != P_FIELDS)
                // wrong number of parameters in the problem line
            {
                printf("Wrong input format!\n");
            }

            if (pos <= 0 || gID <= 0)
                // wrong value of no of arcs or nodes
            {
                printf("Wrong input problem!\n");
            }

            // assign value 
            Gij[cntPair*2] = id1 - 1;
            Gij[cntPair*2+1] = id2 - 1;
            neiCap[cntPair] = value;
            cntPair++;
            break;
        case 'i': // problem description      

            if (
                // reading problem line: type of problem, no of nodes, no of arcs 
                sscanf(in_line, "%*c %d %d %f", &pos, &gID, &value) != P_FIELDS)
                // wrong number of parameters in the problem line
            {
                printf("Wrong input format!\n");
            }

            if (pos <= 0 || gID <= 0)
                // wrong value of no of arcs or nodes
            {
                printf("Wrong input problem!\n");
            }

            // assign value 
            initialCut[(gID - 1)*tempT1 + pos - 1] = value*2;
            break;
        default:
            // unknown type of line 
            printf("Wrong input problem!\n");
            break;
        } // end of switch 
    }     // end of input loop 
    fclose(fp);

    enlarge(initialCut,winSize);

    // assign values into distMatrix T1 X T2 X N 
    distMatrix = new capType*[N];
    for (int gID = 0;gID<N;gID++){
        distMatrix[gID] = new capType[T1*T2];
    }
    for (int x = 0; x < T2; x++){
        for (int y = 0; y < T1; y++){
            for (int gID = 0; gID < N; gID++){
                dif = ref[y][gID] - tst[x][gID];
                distMatrix[gID][y*T2 + x] = dif * dif;
            }
        }
    }

    // free internal memory
    for (int pos = 0; pos < T1; pos++)
        delete[] ref[pos];
    for (int pos = 0; pos < T2; pos++)
        delete[] tst[pos];
    
    delete[] ref;
    delete[] tst;

    return (0);
}

void getMinCut(){
    float** minCut = new float*[tempT1];
    for(int y=0;y<tempT1;y++){
        minCut[y] = new float[N];
        for(int gID=0;gID<N;gID++){
            minCut[y][gID] = (float)initialCut[gID*tempT1+y]/2;
        }
    }
    
    for (int k = 0; k < N; k++){
        cout<<"Graph "<<k<<": cut is ";
        for (llong t = 0; t < T1-1; t++){
            cout<<minCut[t][k]<< " ";
        }
        cout<<endl;
    }
    
    // calculate max flow value 
    float value = 0;
    for (int gID=0;gID<N;gID++){
        int preHeight = 0;
        // first T1-1 columns 
        for (int y = 0;y<T1-1;y++){
            float curHeight = minCut[y][gID];
            for(int x=preHeight;x<=curHeight;x++){
                value = value + distMatrix[gID][y*T2 + x];
            }
            preHeight = curHeight+0.5;
        }
        // last column
        for(int x=preHeight;x<=T2-1;x++){
            value = value + distMatrix[gID][tempT1*T2 + x];
        }
        value = value - distMatrix[gID][0];
    }
    for (int pairID=0;pairID<nPair;pairID++){
        int gID1 = Gij[2*pairID];
        int gID2 = Gij[2*pairID+1];
        for (int y = 0; y < T1-1; y++){
            value = value + abs((minCut[y][gID1]-minCut[y][gID2]))*2*neiCap[pairID];
        }
    }
    cout<<value<<endl;

    for(int y=0;y<tempT1;y++){
        delete[] minCut[y];
    }
    delete[] minCut;
}

int main(int argc, char *argv[]){
    int cc;
    if (argc > 2)
    {
        printf("Usage: %s [update frequency]\n", argv[0]);
        exit(1);
    }

    char filename[] = "D:\\Research\\Graph_accelerate\\Paper_material\\Supplementary\\code\\sample.inp";
    loadInput(filename);

    // printf("Graph size: N = %d, T1 = %d, nPair = %d \n", N, T1, nPair);
    cc = allocDS();
    if (cc) {
        fprintf(stderr, "Allocation error\n");
        exit(1);
    }

    // push upperside
    // initialization 
    printf("Initialization \n");
    init_StageOne();
    // pushRelabel 
    printf("Stage 1 Push relabel \n");
    stageOne();
    printf("Finish push relabel Stage 1  \n");
    minCut_up();
    clearStageOne();

    init_StageTwo();
    printf("Stage 2 Push relabel \n");
    stageTwo();
    printf("Finish push relabel Stage 2  \n");
    minCut_low();
        // clearStageTwo(); No need to clear. Can be implemented by release function.    
    
    getMinCut();
    release();
    // printf("c cut tm:      %10.2f\n", t);
    exit(0);
}

#endif