# MimickAV

MimickAV is a imitation system that can learn to predict the behaviour of different anti-virus engines. It is based on Entropy Profiles. These profiles are extracted using EnTS:

https://github.com/hdg7/EnTS/

If you want to use MimickAV please cite the following paper:

https://www.mdpi.com/1099-4300/21/5/513/htm

Héctor D. Menéndez; José Luis Llorente. Mimicking Anti-Viruses with Machine Learning and Entropy Profiles. Entropy 2019, Volume 21, Issue 5, 513.

## Dataset

The data for the papers is available in the data folder. The format is compatible with MongoDB. To restore the data in a mongo dataset you just need to uncompress it:
```
7z e dataset.7z
mv *json *bson ents
mv ents/ dump/
mongorestore dump/
```

This will create a mongo dataset called ents with different collections [better names coming]:

- **classifiers**: Classification results for the packed dataset.
- **classifiersUPck**: Classification results for the non-packed dataset.
- **classifiersMix**: Classification results for the mix dataset.
- **ROCPck**: Results for the ROC curves of the three datasets
- **ents**: Entropy profiles, gGenerated with EntS
- **av**: anti-virus reports for malware, obtained with VirusTotal
- **packerClass**: Packers's families
- **packerMal**: Packers for malware and benign-ware

## Software

To create the data that you can find from the paper, you just need to use the following programs:

- **classification.R**: Runs the classifiers using the information from ents and av datasets (see the dataset section). It creates the classifier dataset.
- **classificationUPck.R**: Equivalent to the former but for non-packed data.
- **classificationMix.R**: Equivalent to the former but for Mix data.
- **classificationROC.R**: Creates the ROC curve for Pck data.
- **classificationROCUPck.R**: Creates the ROC curve for non-packed data.
- **classificationROCMix.R**: Creates the ROC curve for Mix data.

To adapt it to your MongoDB software, change the script with your database info. In our case, the database is in a local network url="mongodb://viru8", you can change the domain name with yours.

Example of running (for the ROC is equivalent):

```
./classification.R repetition_num
./classification.R 0
```

You need to set up your Mongo system in advance.

