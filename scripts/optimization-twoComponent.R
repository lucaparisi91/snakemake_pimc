source("scripts/model.R")
# import 
data=read_delim(snakemake@input[[1]],delim = "\t") %>% drop_na()
data$folder <- NULL
data
groups <- c()
#M <-  M %>% filter( abs(.data$inverseTemperature - 1.42857142857143)<1e-2)
parameter="CA"
ob = "ccRatio"
blockAverage<- function( data,  n=10 )
{

data %>% split(  seq_along(rownames(data))%%n     ) %>% map_dfr ( ~ .x%>% summarise( across(.fns = mean  ) ) ) %>% mutate(iteration=seq_along(iteration) )
}

data <- data %>% group_by( across(all_of(c(groups,"CA")))) %>% group_modify(  ~  blockAverage(.x) ) 

#plot <- ggplot( data=data,aes(x=.data[["iteration"]],y=.data[[ob]],color=as.factor(.data[[parameter]]) )) + geom_point( aes_string(y=ob)  ) + facet_grid( nBeads  ~N) 

#ggplotly(plot)

############### FILTERING ############################

averageRatios <- data %>% group_by( across(all_of(c(groups,parameter)))) %>% summarise( across(.cols=c("ccRatio","ocRatio","coRatio","ooRatio"),.fns=mean) )
filteredRatios <- averageRatios %>% filter(ccRatio<0.9  & ooRatio > 0.1)
data <- inner_join( data, filteredRatios %>% select( .data[["CA"]])  )
################## EXTRACT Z #########################################

noc <- function(data) { return (tibble( ZA =  log(mean(data[["ocRatio"]])/mean(data[["ccRatio"]])), ZAB =  log(mean(data[["ooRatio"]])/mean(data[["ccRatio"]]))  , ZB =  log(mean(data[["coRatio"]])/mean(data[["ccRatio"]]))
                                      )   )  }

sectors=c("A","B","AB")

sectorCoefficients <- map_chr( sectors, ~ str_glue("C{.x}"))

NOC_data <- data %>% group_by(across(all_of(  c(groups,sectorCoefficients ) ))) %>% group_modify( ~ bootstrapAverage(.x, noc) )  %>%drop_na() %>% mutate(ZA_mean=(ZA_mean-log(CA)),ZA_error=ZA_error ) %>%   mutate(ZAB_mean=(ZAB_mean-log(CAB)),ZAB_error=ZAB_error ) %>% mutate(ZB_mean=(ZB_mean-log(CB)),ZB_error=ZB_error )


NOC_data <- NOC_data %>% addErrorLimits(average="ZA_mean",error="ZA_error")  %>% addErrorLimits("ZAB_mean","ZAB_error") %>%addErrorLimits(average="ZB_mean",error="ZB_error")

Z <- NOC_data %>% stripMeanNames()
Z

sectors <-c("ZA","ZB","ZAB") 
for ( sector in sectors ) {
  plot <- ggplot( data=Z,aes(x=CA,y=.data[[sector]] ) )+ geom_point( aes_string(y=sector)  ) + geom_errorbar(aes_string(ymin=str_glue("{sector}_lwr"),ymax=str_glue("{sector}_upr") ),width=5e-2*max(Z$CA))  + geom_smooth(method="lm" )
  #ggsave(str_glue("{sector}.pdf"),plot=plot )
}


write_delim(Z,snakemake@output[[2]],delim="\t")


Z_summ <- Z %>% ungroup() %>%summarise( ZA_error=sqrt(var(ZA)/length(ZA)),ZA=mean(ZA),ZB_error=sqrt(var(ZB)/length(ZB)),ZB=mean(ZB),ZAB_error=sqrt(var(ZAB)/length(ZAB)),ZAB=mean(ZAB) )

write_delim(Z_summ,snakemake@output[[1]],delim="\t")
