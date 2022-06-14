# import 
source("scripts/model.R")

data=read_delim(snakemake@input[[1]],delim = "\t") %>% drop_na()

parameter="CA"
groups=c("N")
ob = "cRatio"
nBlocks=10

averageBlock <- function(data,n=10)
{
  data %>% split(  seq_along(rownames(data))%%nBlocks     ) %>% map_dfr(~ summarize(.x,across(.fns=mean)))  %>% mutate(iteration=seq_along(iteration) )
}
data <- data %>% group_by( across(all_of(parameter))) %>% group_modify( ~ averageBlock(.x) ) 

plot <- ggplot( data=data,aes(x=.data[["iteration"]],y=.data[[ob]],color=as.factor(.data[[parameter]]) )) + geom_point( aes_string(y=ob)  )

ggsave("ccRatio.pdf",plot)

############### FILTERING ############################
averageRatios <- data %>% group_by( across(all_of(c(groups,parameter)))) %>% summarise( across(.cols=c("cRatio","oRatio"),.fns=mean) )
averageRatios
filteredRatios <- averageRatios %>% filter(cRatio<0.99  & oRatio > 0.01)
filteredRatios
data <- inner_join( data, filteredRatios %>% select( .data[["CA"]])  )
data
################## EXTRACT Z #########################################

#noc <- function(data) { return (tibble( ZA =  log(mean(data[["ocRatio"]])/mean(data[["ccRatio"]])), ZAB =  log(mean(data[["ooRatio"]])/mean(data[["ccRatio"]]))  , ZB =  log(mean(data[["coRatio"]])/mean(data[["ccRatio"]]))
#)   )  }

noc <- function(data) {  return (tibble( ZA =  log(mean(data[["oRatio"]])/mean(data[["cRatio"]])    )      ) )   }


NOC_data <- data %>% group_by(across(all_of(  c("CA") ))) %>% group_modify( ~ bootstrapAverage(.x, noc) )  %>%drop_na() %>% mutate(ZA_mean=ZA_mean-log(CA),ZA_error=ZA_error ) 
#%>%   mutate(ZAB_mean=(ZAB_mean-log(CAB))/N,ZAB_error=ZAB_error/N ) %>% mutate(ZB_mean=(ZB_mean-log(CB))/N,ZB_error=ZB_error/N )
NOC_data

NOC_data <- NOC_data %>% addErrorLimits(average="ZA_mean",error="ZA_error") 
#%>% addErrorLimits("ZAB_mean","ZAB_error") %>%addErrorLimits(average="ZB_mean",error="ZB_error")
Z <- NOC_data %>% stripMeanNames()
plot <- ggplot( data=Z,aes(x=CA,y=.data[["ZA"]] ) )+ geom_point( aes_string(y="ZA")  ) + geom_errorbar(aes(ymin=ZA_lwr,ymax=ZA_upr)) + geom_smooth(method="lm" )
#ggsave("Z.pdf",plot)
Z <- Z %>% ungroup() %>%summarise( ZA_error=sqrt(var(ZA)/length(ZA)),ZA=mean(ZA) )


write_delim(Z,snakemake@output[[1]],delim="\t")






