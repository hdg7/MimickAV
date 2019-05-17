#!/usr/bin/Rscript

library(mongolite)
entsCollect = mongo(collection = "ents", db="ents", url="mongodb://viru8")
#entsData=entsCollect$find('{"Malware":"True"}')

entsData=entsCollect$find('{}')


avCollect = mongo(collection = "av", db="ents", url="mongodb://viru8")
avData=avCollect$find('{}')

avViruses<-colnames(avData)[-1]

finalAVs={}
for (avEngine in avViruses){
    if(sum(avData[avEngine]=='?')<500)
    {
	finalAVs <- c(finalAVs, avEngine)
    }
}

avClasses = mongo(collection = "classifiers", db="ents", url="mongodb://viru8")
                                        #doneAV<-avClasses$distinct("AV",paste('{"Repetition": "',repetition,'"}',sep=""))
doneAV <- c("eGambit","TheHacker","Kaspersky")
print(doneAV)
finalAVs<-finalAVs[(finalAVs %in% doneAV)]
print(finalAVs)

avDataFinal <- avData[,c('MD5',finalAVs)]
finalAVsClean <- gsub("-", "", finalAVs)
print(finalAVsClean)
colnames(avDataFinal)<-c('MD5',finalAVsClean)
rownames(entsData)<-entsData[,'Hash']
rownames(avDataFinal)<-avDataFinal[,'MD5']
de <- merge(entsData,avDataFinal,0,all=TRUE)

timeSeq<-{}
for (i in seq(1,512)){
    timeSeq<-c(timeSeq,paste("T",i,sep=""))
}

de[is.na(de)] <- 0
de[de=="?"]<-NA
de<-de[complete.cases(de),]
rownames(de)<-de[,"Hash"]



#Classification

rocCollect = mongo(collection = "ROCPck", db="ents", url="mongodb://viru8")
library(mlr)


classifierList <-"classif.boosting"
##     c("classif.xgboost",
## "classif.ada",
## "classif.boosting",
## "classif.gbm",
## "classif.h2o.deeplearning",
## "classif.h2o.gbm",
## "classif.h2o.glm",
## "classif.h2o.randomForest",
## "classif.IBk",
## "classif.J48",
## "classif.JRip",
## "classif.knn",
## "classif.ksvm",
## "classif.lvq1",
## #"classif.multinom",
## "classif.naiveBayes",
## "classif.nnet",#,MaxNWts=2000
## "classif.OneR",
## "classif.PART",
## #"classif.probit",
## #"classif.qda",
## "classif.rpart",
## "classif.svm"
## )


for (chosenAV in finalAVsClean)
{

    features<-c(timeSeq, chosenAV)
    de[,timeSeq]<-sapply(de[,timeSeq],as.numeric)
    packedMalInd<-which(de[,chosenAV]==1 & de[,"Packed"]=="True")
    unpackedMalInd<-which(de[,chosenAV]==1 & de[,"Packed"]=="False")

    if(length(packedMalInd)==0 || length(unpackedMalInd)==0){
	next
    }
    if((length(packedMalInd)<1000) || (length(unpackedMalInd)<1000))
    {
        if(length(packedMalInd)<2000){
            packedMalIndExtra<-which(de[,chosenAV]==0 & de[,"Malware"]=="True" & de[,"Packed"]=="True")
            set.seed(10)
            packedMalIndExtra <- sample(packedMalIndExtra,1000-length(packedMalInd))
            packedMalInd<-c(packedMalInd,packedMalIndExtra)
        } else if(length(unpackedMalInd)<1000){
            unpackedMalIndExtra<-which(de[,chosenAV]==0 & de[,"Malware"]=="True" & de[,"Packed"]=="False")
            set.seed(10)
            unpackedMalIndExtra <- sample(unpackedMalIndExtra,1000-length(unpackedMalInd))
            unpackedMalInd<-c(unpackedMalInd,unpackedMalIndExtra)
        }
    }
    else {
        set.seed(10)
        packedMalInd <- sample(packedMalInd,1000)
        unpackedMalInd <- sample(unpackedMalInd,1000)
    }
    packedBenInd<-which(de[,"Malware"]=="False" & de[,"Packed"]=="True")
    packedBenInd<-sample(packedBenInd,1000)
    unpackedBenInd<-which(de[,"Malware"]=="False" & de[,"Packed"]=="False")
    unpackedBenInd<-sample(unpackedBenInd,1000)
    packedData<-de[c(packedMalInd, unpackedMalInd,packedBenInd,unpackedBenInd),features]
                                        #Creating the PcK datasets:
#    packedMalInd<-which(de[,"Malware"]=="True" & de[,"Packed"]=="True")

    a=as.numeric(Sys.time())
    set.seed(a)
    tsk = makeClassifTask(data= packedData,target=chosenAV)
    ho= makeResampleInstance("Holdout",tsk)
    tsk.train= subsetTask(tsk,ho$train.inds[[1]])
    tsk.test= subsetTask(tsk,ho$test.inds[[1]])
    classifier <- classifierList
#    for (classifier in classifierList)
#    {
    if(classifier == "classif.nnet"){
        lrn= makeLearner(classifier,predict.type = "prob",MaxNWts=2000)
    } else{
        lrn= makeLearner(classifier,predict.type = "prob")
    }
    mdl = train(lrn,tsk.train)
    prd= predict(mdl,tsk.test)
    
    df <- generateThreshVsPerfData(prd, measures=list(fnr,tnr))
    df <- df$data
    df<- cbind(rep("Mix",length(df[,1])), df)
    colnames(df)[1]<-"PcK"
    df<- cbind(rep(chosenAV,length(df[,1])), df)
    colnames(df)[1]<-chosenAV  
    rocCollect$insert(df)
#    }
}
                                        #cv = makeResampleDesc("CV",iters=5)
                                        #mdl = train(lrn,tsk.train)
                                        #prd= predict(mdl,tsk.test)
                                        #performance( pred=prd, measures=acc)
                                        #lrn= makeLearner("classif.bst")
                                        #mdl = train(lrn,tsk.train)
                                        #prd= predict(mdl,tsk.test)
                                        #performance( pred=prd, measures=acc)
#ps= makeParamSet(makeNumericParam("eta",0,1),makeNumericParam("lambda",0,200),makeIntegerParam("max_depth",1,20))
#tc= makeTuneControlIrace(budget=100)
#tr= tuneParams(lrn,tsk.train,cv,acc,ps,tc)
#lrn= setHyperPars(lrn,par.vals=tr$x)

#mdl = train(lrn,tsk.train)
#prd= predict(mdl,tsk.test)
#performance( pred=prd, measures=acc)
