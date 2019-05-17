# MimickAV

MimickAV is a imitation system that can learn to predict the behaviour of different anti-virus engines. It is based on Entropy Profiles. These profiles are extracted using EnTS:

https://github.com/hdg7/EnTS/

If you want to use MimickAV please cite the following paper:

----

## Dataset

The data for the papers is available in the data folder. The format is compatible with MongoDB. To restore the data in a mongo dataset you just need to uncompress it:
```
7z e dataset.7z
mv *json *bson ents
mv ents/ dump/
mongorestore dump/
```

This will create a mongo dataset called ents with different collections:

- **classifiers**: Classification results for the packed dataset.
- **classifiersUPck**: Classification results for the non-packed dataset.
- **classifiersMix**: Classification results for the mix dataset.
- **ROCPck**: Results for the ROC curves of the three datasets
- **ents**: Entropy profiles
- **av**: anti-virus reports for malware
- **packerClass**: Packers's families
- **packerMal**: Packers for malware and benign-ware
