
## ------------------------------------------------------------------------

U.Data<-read.csv("http://files.grouplens.org/datasets/movielens/ml-100k/u.data",header = FALSE,sep = "\t",col.names = c("User_ID","Item_ID","Rating","TimeStamp"))

U.Item<-read.csv("http://files.grouplens.org/datasets/movielens/ml-100k/u.item",header=FALSE,sep="|",col.names = c("movie_id","movie_title","release_date","video_release_date","IMDb URL", "unknown","Action","Adventure","Animation","Children's","Comedy","Crime",    "Documentary","Drama","Fantasy","Film-Noir","Horror","Musical","Mystery","Romance"     ,"Sci-Fi","Thriller","War","Western"),as.is = TRUE)

U.User<-read.csv("http://files.grouplens.org/datasets/movielens/ml-100k/u.user",header=FALSE,sep="|",col.names = c("User_ID","age","gender","occupation","zip code"))


U.Genres<-read.csv("http://files.grouplens.org/datasets/movielens/ml-100k/u.genre",header=FALSE,sep="|",col.names = c("genre","Number"))




## ------------------------------------------------------------------------
#Remove "Video Release date" as it has no data

#sum(is.na(U.Item[,4]))
U.Item<-U.Item[,-4]



## ------------------------------------------------------------------------
#merge the dataset

UData_User<-merge(U.Data,y = U.User,by = "User_ID")

# group by occupation,item_id 
groupby<-by(UData_User,list(UData_User$occupation,UData_User$Item_ID),FUN = function(x) 
  {
  data.frame(occupation=unique(x$occupation),
  Item_ID=unique(x$Item_ID),
  mean_rating=mean(x$Rating),
  Count_Item_ID=nrow(x)
  )
  })

Top3Occupation<-do.call(rbind,groupby)
Top3Occupation<-Top3Occupation[with(Top3Occupation,order(occupation,-mean_rating,-Count_Item_ID)),]


# pick top 3 

Top3Occupation<-by(Top3Occupation,list(Top3Occupation$occupation),head,n=3) 
Top3Occupation<-do.call(rbind.data.frame,Top3Occupation)
rownames(Top3Occupation)<-NULL

# Get the names of the movie

Top3Occupation<-merge(Top3Occupation,U.Item[,1:2],by.x = "Item_ID",by.y = "movie_id",sort = FALSE)
Top3Occupation<-Top3Occupation[with(Top3Occupation,order(occupation,-mean_rating,-Count_Item_ID)),]

write.csv(x = Top3Occupation,file = "Top3Occupation.csv")



## ------------------------------------------------------------------------

#reversing one-hot encoding to match to the dataset

rev_one_hot<-as.data.frame(which(U.Item[,5:23]==1,arr.ind = T))
rev_one_hot$genre_transformed<-names(U.Item[,5:23])[rev_one_hot[order(rev_one_hot[,1]),2]]
Genre<-merge(U.Item,rev_one_hot,by.x = "movie_id",by.y = "row")




## ------------------------------------------------------------------------
# merging Genre with UData on Item Id 
UGenre<-Genre[,c(1,2,25)]
UGenreUser<-merge(UGenre,U.Data,by.x ="movie_id",by.y = "Item_ID" )

#group by Genre

groupby<-by(UGenreUser,list(UGenreUser$genre_transformed,UGenreUser$movie_id),FUN = function(x) 
  {
  data.frame(genre_transformed=unique(x$genre_transformed),
  Item_ID=unique(x$movie_id),
  movie_title=unique(x$movie_title),
  mean_rating=mean(x$Rating),
  Count_Item_ID=nrow(x)
  )
  })

Top3Genre<-do.call(rbind,groupby)
Top3Genre<-Top3Genre[with(Top3Genre,order(genre_transformed,-mean_rating,-Count_Item_ID)),]


# pick top 3 

Top3Genre<-by(Top3Genre,list(Top3Genre$genre_transformed),head,n=3) 
Top3Genre<-do.call(rbind.data.frame,Top3Genre)
rownames(Top3Genre)<-NULL


write.csv(x = Top3Genre,file = "Top3Genre.csv")




## ------------------------------------------------------------------------
# merging data 

UGenreUser_Occupation<-merge(UGenreUser,U.User,by="User_ID")

#  group by occupation,genre

groupby<-by(UGenreUser_Occupation,list(UGenreUser_Occupation$occupation,UGenreUser_Occupation$genre_transformed,UGenreUser_Occupation$movie_id),FUN = function(x) 
  {
  data.frame(occupation=unique(x$occupation),
  genre_transformed=unique(x$genre_transformed),
  movie_id=unique(x$movie_id),
  mean_rating=mean(x$Rating),
  Count_Item_ID=nrow(x)
  )
  })

Top3OccupationGenre<-do.call(rbind,groupby)
Top3OccupationGenre<-Top3OccupationGenre[with(Top3OccupationGenre,order(occupation,genre_transformed,-mean_rating,-Count_Item_ID)),]

Top3OccupationGenre<-aggregate(Top3OccupationGenre,by=list(Top3OccupationGenre$occupation,Top3OccupationGenre$genre_transformed),FUN = head,n=3)





## ------------------------------------------------------------------------

# find the oldest user

max_age=max(U.User$age)

U.User$age_bracket<- cut(U.User$age, breaks = c(0,6, 12, 18, 30, 50,(max_age+1)),
      labels = c("0-6", "6-12", "12-18", "18-30","30-50","50+"),
      right = T)

# grouping by Age bracket


UAgeUser<-merge(U.User,U.Data,by.x ="User_ID",by.y = "User_ID" )
groupby<-by(UAgeUser,list(UAgeUser$age_bracket,UAgeUser$Item_ID),FUN = function(x) 
  {
  data.frame(age_bracket=unique(x$age_bracket),
  Item_ID=unique(x$Item_ID),
  mean_rating=mean(x$Rating),
  Count_Item_ID=nrow(x)
  )
  })

Top3Age_Group<-do.call(rbind,groupby)
  Top3Age_Group<-Top3Age_Group[with(Top3Age_Group,order(age_bracket,-mean_rating,-Count_Item_ID)),]


# pick top 3 

Top3Age_Group<-by(Top3Age_Group,list(Top3Age_Group$age_bracket),head,n=3) 
Top3Age_Group<-do.call(rbind.data.frame,Top3Age_Group)
rownames(Top3Age_Group)<-NULL


# Get the names of the movie

Top3Age_Group<-merge(Top3Age_Group,U.Item[,1:2],by.x = "Item_ID",by.y = "movie_id",sort = FALSE)
Top3Age_Group<-Top3Age_Group[with(Top3Age_Group,order(age_bracket,-mean_rating,-Count_Item_ID)),]



write.csv(x = Top3Age_Group,file = "Top3Age_Group.csv")



## ------------------------------------------------------------------------

#subsetting the data frame by selecting movies released in Summer

Genre$release_date<-as.Date(Genre$release_date,format="%d-%b-%y")
Genre$release_date<-format (Genre$release_date, "%b")
Genre_Summer<-Genre[Genre$release_date %in% c("May","June","July"),]

Genre_Summer<-Genre_Summer[,c(1:3,25)]

# merging data 

Genre_Summer<-merge(Genre_Summer,U.Data,by.x = "movie_id","Item_ID")


groupby<-by(Genre_Summer,list(Genre_Summer$genre_transformed),FUN = function(x) 
  {
  data.frame(genre_transformed=unique(x$genre_transformed),
  mean_rating=mean(x$Rating),
  Count_Item_ID=nrow(x)
  )
  })

Top3Genre_Summer<-do.call(rbind,groupby)
Top3Genre_Summer<-Top3Genre_Summer[with(Top3Genre_Summer,order(-mean_rating,-Count_Item_ID)),]


# pick top 3 

Top3Genre_Summer<-head(Top3Genre_Summer,n = 3) 
rownames(Top3Genre_Summer)<-NULL


write.csv(x = Top3Genre_Summer,file = "Top3Genre_Summer.csv")



## ------------------------------------------------------------------------

# correlation matrix would give us what genres are closed to what genres 
Correlation_Matrix<-cor(U.Item[,5:23])
Correlation_Matrix<-as.data.frame(Correlation_Matrix)

find_co_occuring<-function(cname)
{
  top2<-tail(head(with(Correlation_Matrix,order(-cname)),n=3),n = 2)
  rownames(Correlation_Matrix)[top2]
}

Top2CoOccuring<-apply(Correlation_Matrix, 2, find_co_occuring)


write.csv(x = Top2CoOccuring,file = "Top2CoOccuring.csv")


