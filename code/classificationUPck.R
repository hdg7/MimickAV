#!/usr/bin/Rscript

##    
##    Copyright (C) 2019 by Hector D. Menendez <hector.david.1987@gmail.com>
##    This program is free software: you can redistribute it and/or modify
##    it under the terms of the GNU General Public License as published by
##    the Free Software Foundation, either version 3 of the License, or
##    (at your option) any later version.
##    This program is distributed in the hope that it will be useful,
##    but WITHOUT ANY WARRANTY; without even the implied warranty of
##    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##    GNU General Public License for more details.
##    You should have received a copy of the GNU General Public License
##    along with this program.  If not, see <https://www.gnu.org/licenses/>.

library(mongolite)
entsCollect = mongo(collection = "ents", db="ents", url="mongodb://viru8")
#entsData=entsCollect$find('{"Malware":"True"}')

args<-commandArgs(TRUE)
repetition <- args[1]
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

avClasses = mongo(collection = "classifiersUPck", db="ents", url="mongodb://viru8")
doneAV<-avClasses$distinct("AV",paste('{"Repetition": "',repetition,'"}',sep=""))
print(doneAV)
finalAVs<-finalAVs[!(finalAVs %in% doneAV)]
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

classCollect = mongo(collection = "classifiersUPck", db="ents", url="mongodb://viru8")
library(mlr)


classifierList <- c("classif.xgboost",
"classif.ada",
"classif.boosting",
"classif.gbm",
"classif.h2o.deeplearning",
"classif.h2o.gbm",
"classif.h2o.glm",
"classif.h2o.randomForest",
"classif.IBk",
"classif.J48",
"classif.JRip",
"classif.knn",
"classif.ksvm",
"classif.lvq1",
#"classif.multinom",
"classif.naiveBayes",
"classif.nnet",#,MaxNWts=2000
"classif.OneR",
"classif.PART",
#"classif.probit",
#"classif.qda",
"classif.rpart",
"classif.svm"
)


for (chosenAV in finalAVsClean)
{

    features<-c(timeSeq, chosenAV)
    de[,timeSeq]<-sapply(de[,timeSeq],as.numeric)

                                        #Creating the PcK datasets:
#    packedMalInd<-which(de[,"Malware"]=="True" & de[,"Packed"]=="True")
    packedMalInd<-which(de[,chosenAV]==1 & de[,"Packed"]=="False")
    if(length(packedMalInd)==0){
	next
} else if(length(packedMalInd)<2000){
    packedMalIndExtra<-which(de[,chosenAV]==0 & de[,"Malware"]=="True" & de[,"Packed"]=="False")
    	set.seed(10)
    packedMalIndExtra <- sample(packedMalIndExtra,2000-length(packedMalInd))
    packedMalInd<-c(packedMalInd,packedMalIndExtra)
  } else {
   set.seed(10)
    packedMalInd <- sample(packedMalInd,2000)
    }
    packedBenInd<-which(de[,"Malware"]=="False" & de[,"Packed"]=="False")
    packedData<-de[c(packedMalInd, packedBenInd),features]

    a=as.numeric(Sys.time())
    set.seed(a)
    tsk = makeClassifTask(data= packedData,target=chosenAV)
    ho= makeResampleInstance("Holdout",tsk)
    tsk.train= subsetTask(tsk,ho$train.inds[[1]])
    tsk.test= subsetTask(tsk,ho$test.inds[[1]])

    for (classifier in classifierList)
    {
        if(classifier == "classif.nnet"){
            lrn= makeLearner(classifier,MaxNWts=2000)
        } else{
            lrn= makeLearner(classifier)
        }
        mdl = train(lrn,tsk.train)
        prd= predict(mdl,tsk.test)
        accuracy<-performance( pred=prd, measures=acc)
        str <- paste('{"classifier": "', classifier , '", "AV" : "' , finalAVs[which(finalAVsClean == chosenAV)] ,'" , "Accuracy" : "', toString(accuracy) ,'","Repetition": "', repetition ,'"}',sep='')
        classCollect$insert(str)        
    }
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
