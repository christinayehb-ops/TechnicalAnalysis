# BDA400 - Assignment 6
# Technical Analysis using R - Visualization Phase
# Student: Christina Gebrekirstoes

required_packages <- c("shiny", "ggplot2", "quantmod", "TTR", "gridExtra")
missing_packages <- required_packages[!(required_packages %in% installed.packages()[, "Package"])]
if (length(missing_packages) > 0) install.packages(missing_packages, dependencies = TRUE)
library(shiny); library(ggplot2); library(quantmod); library(TTR); library(gridExtra)

fetch_stock_data <- function(symbol, start_date, end_date, source_choice) {
  symbol <- toupper(trimws(symbol))
  if (!grepl("^[A-Z0-9._^-]+$", symbol) || nchar(symbol) == 0) stop("Please enter a valid stock symbol.")
  fetch_one <- function(src) suppressWarnings(getSymbols(symbol, src=src, from=as.Date(start_date), to=as.Date(end_date)+1, auto.assign=FALSE, warnings=FALSE))
  preferred_src <- if (source_choice == "Yahoo Finance") "yahoo" else "stooq"
  alternate_src <- if (preferred_src == "yahoo") "stooq" else "yahoo"
  data <- tryCatch(fetch_one(preferred_src), error=function(e) NULL); source_used <- preferred_src
  if (is.null(data) || NROW(data)==0) { data <- tryCatch(fetch_one(alternate_src), error=function(e) NULL); source_used <- alternate_src }
  if (is.null(data) || NROW(data)==0) stop("Stock data could not be retrieved from Yahoo Finance or Stooq.")
  data <- data[order(index(data))]; attr(data,"source_used") <- source_used; data
}
convert_timeframe <- function(x,timeframe) {
  if (timeframe=="Daily") return(x)
  period_name <- if (timeframe=="Weekly") "weeks" else "months"
  converted <- to.period(x, period=period_name, indexAt="lastof", drop.time=TRUE)
  colnames(converted) <- sub("^[^.]+\\.","",colnames(converted)); converted
}
xts_to_df <- function(x) {
  cn <- colnames(x); get_col <- function(pattern) { hit <- grep(pattern,cn,ignore.case=TRUE,value=TRUE); if(length(hit)==0) return(rep(NA_real_,NROW(x))); as.numeric(x[,hit[1]]) }
  data.frame(Date=as.Date(index(x)),Open=get_col("Open$"),High=get_col("High$"),Low=get_col("Low$"),Close=get_col("Close$"),Volume=get_col("Volume$"),Adjusted=get_col("Adjusted$"))
}

ui <- fluidPage(
  tags$head(tags$style(HTML("body{background-color:#f7f9fc}.control-card{background:white;padding:18px;border-radius:10px;box-shadow:0 1px 5px rgba(0,0,0,.08)}.metric-card{background:white;padding:12px;border-radius:8px;margin-bottom:10px;border:1px solid #e5e9f0}"))),
  h2("BDA400 - Interactive Technical Analysis Dashboard"), p("Stock visualization, technical indicators, and trading-signal analysis using R Shiny"),
  sidebarLayout(sidebarPanel(width=3,div(class="control-card",h4("Data Selection"),textInput("symbol","Stock Symbol","AAPL"),selectInput("source","Data Source",c("Yahoo Finance","Stooq")),dateRangeInput("date_range","Date Range",start=Sys.Date()-365,end=Sys.Date(),max=Sys.Date()),selectInput("timeframe","Time Frame",c("Daily","Weekly","Monthly")),selectInput("chart_type","Chart Type",c("Line","Candlestick","Area")),hr(),h4("Technical Indicators"),checkboxGroupInput("indicators","Turn indicators on/off",c("Moving Averages"="MA","RSI"="RSI","MACD"="MACD"),selected=c("MA","RSI","MACD")),numericInput("fast_ma","Fast SMA Period",20,min=2,max=200),numericInput("slow_ma","Slow SMA Period",50,min=3,max=300),hr(),h4("Trading Rule Parameters"),checkboxInput("rsi_confirm","Require RSI confirmation",FALSE),sliderInput("rsi_mid","RSI confirmation level",40,60,50),checkboxInput("macd_confirm","Require MACD confirmation",FALSE),actionButton("refresh","Refresh Analysis",class="btn-primary",width="100%"))),
  mainPanel(width=9,fluidRow(column(4,div(class="metric-card",strong("Data Source Used"),br(),textOutput("source_used"))),column(4,div(class="metric-card",strong("Latest Close"),br(),textOutput("latest_close"))),column(4,div(class="metric-card",strong("Latest Trading State"),br(),textOutput("latest_signal")))),div(class="control-card",plotOutput("stock_chart",height="720px"),h4("Trading Signal Summary"),tableOutput("signal_table"))))
)

server <- function(input,output,session) {
 raw_stock <- eventReactive(list(input$refresh,input$symbol,input$source,input$date_range,input$timeframe),{
  req(input$symbol,input$date_range); validate(need(input$date_range[1]<input$date_range[2],"The start date must be before the end date."))
  tryCatch({x<-fetch_stock_data(input$symbol,input$date_range[1],input$date_range[2],input$source); used<-attr(x,"source_used"); x<-convert_timeframe(x,input$timeframe); attr(x,"source_used")<-used; x},error=function(e){showNotification(e$message,type="error");NULL})
 },ignoreNULL=FALSE)
 analysis_data <- reactive({
  x<-raw_stock(); validate(need(!is.null(x)&&NROW(x)>0,"No stock data is available.")); df<-xts_to_df(x); df<-df[complete.cases(df[,c("Date","Open","High","Low","Close")]),]
  validate(need(input$fast_ma<input$slow_ma,"Fast SMA period must be smaller than Slow SMA."),need(nrow(df)>input$slow_ma+2,"Selected date range is too short."))
  df$FastSMA<-SMA(df$Close,n=input$fast_ma); df$SlowSMA<-SMA(df$Close,n=input$slow_ma); df$RSI<-RSI(df$Close,n=14)
  m<-MACD(df$Close,nFast=12,nSlow=26,nSig=9,percent=FALSE); df$MACD<-as.numeric(m[,1]); df$MACDSignal<-as.numeric(m[,2]); df$MACDHist<-df$MACD-df$MACDSignal
  up<-df$FastSMA>df$SlowSMA & c(FALSE,head(df$FastSMA,-1)<=head(df$SlowSMA,-1)); down<-df$FastSMA<df$SlowSMA & c(FALSE,head(df$FastSMA,-1)>=head(df$SlowSMA,-1)); up[is.na(up)]<-FALSE; down[is.na(down)]<-FALSE
  rb<-if(isTRUE(input$rsi_confirm)) df$RSI>=input$rsi_mid else rep(TRUE,nrow(df)); rs<-if(isTRUE(input$rsi_confirm)) df$RSI<=input$rsi_mid else rep(TRUE,nrow(df)); mb<-if(isTRUE(input$macd_confirm)) df$MACD>df$MACDSignal else rep(TRUE,nrow(df)); ms<-if(isTRUE(input$macd_confirm)) df$MACD<df$MACDSignal else rep(TRUE,nrow(df))
  buy<-up&rb&mb; sell<-down&rs&ms; buy[is.na(buy)]<-FALSE; sell[is.na(sell)]<-FALSE; df$Signal<-"Hold"; df$Signal[buy]<-"Buy"; df$Signal[sell]<-"Sell"
  df$TradingState<-ifelse(is.na(df$FastSMA)|is.na(df$SlowSMA),"Insufficient history",ifelse(df$FastSMA>df$SlowSMA,"Bullish / Hold",ifelse(df$FastSMA<df$SlowSMA,"Bearish / Hold","Neutral / Hold"))); attr(df,"source_used")<-attr(x,"source_used"); df
 })
 output$source_used<-renderText({if(identical(attr(analysis_data(),"source_used"),"yahoo")) "Yahoo Finance" else "Stooq"}); output$latest_close<-renderText({paste0("$",format(round(tail(analysis_data()$Close,1),2),nsmall=2))}); output$latest_signal<-renderText({df<-analysis_data(); paste("Current:",tail(df$TradingState,1))})
 output$stock_chart<-renderPlot({
  df<-analysis_data(); if(input$chart_type=="Line") p<-ggplot(df,aes(Date,Close))+geom_line() else if(input$chart_type=="Area") p<-ggplot(df,aes(Date,Close))+geom_area(alpha=.35)+geom_line() else {df$Direction<-ifelse(df$Close>=df$Open,"Up","Down"); w<-if(input$timeframe=="Daily") .7 else if(input$timeframe=="Weekly") 4.5 else 18; p<-ggplot(df,aes(Date))+geom_segment(aes(xend=Date,y=Low,yend=High))+geom_rect(aes(xmin=Date-w/2,xmax=Date+w/2,ymin=pmin(Open,Close),ymax=pmax(Open,Close),fill=Direction))+scale_fill_manual(values=c("Up"="#2e8b57","Down"="#c94c4c"),guide="none")}
  if("MA"%in%input$indicators) p<-p+geom_line(aes(y=FastSMA),color="#1565c0",na.rm=TRUE)+geom_line(aes(y=SlowSMA),color="#ef6c00",na.rm=TRUE)
  sig<-df[df$Signal%in%c("Buy","Sell"),]; if(nrow(sig)>0) p<-p+geom_point(data=sig,aes(Date,Close,shape=Signal,color=Signal),size=3)+geom_text(data=sig,aes(Date,Close,label=Signal,color=Signal),vjust=-1)+scale_shape_manual(values=c("Buy"=24,"Sell"=25))+scale_color_manual(values=c("Buy"="#1b8a3f","Sell"="#b3261e"))
  p<-p+labs(title=paste(toupper(input$symbol),input$timeframe,input$chart_type,"Chart"),subtitle=paste0("Trading rule: SMA(",input$fast_ma,") / SMA(",input$slow_ma,") crossover"),x=NULL,y="Price",caption="Data requested from Yahoo Finance/Stooq via quantmod")+theme_minimal()
  plots<-list(p); heights<-c(3.5); if("RSI"%in%input$indicators){pr<-ggplot(df,aes(Date,RSI))+geom_line(na.rm=TRUE)+geom_hline(yintercept=c(30,70),linetype="dashed")+coord_cartesian(ylim=c(0,100))+labs(y="RSI",title="Relative Strength Index (14)")+theme_minimal(); plots<-append(plots,list(pr)); heights<-c(heights,1.2)}; if("MACD"%in%input$indicators){pm<-ggplot(df,aes(Date))+geom_col(aes(y=MACDHist,fill=MACDHist>=0),alpha=.45,show.legend=FALSE)+geom_line(aes(y=MACD),na.rm=TRUE)+geom_line(aes(y=MACDSignal),na.rm=TRUE)+labs(y="MACD",title="MACD (12, 26, 9)")+theme_minimal(); plots<-append(plots,list(pm)); heights<-c(heights,1.2)}; do.call(gridExtra::grid.arrange,c(plots,list(ncol=1,heights=heights)))
 })
 output$signal_table<-renderTable({df<-analysis_data(); s<-df[df$Signal%in%c("Buy","Sell"),c("Date","Close","FastSMA","SlowSMA","RSI","MACD","MACDSignal","Signal")]; if(nrow(s)==0) return(data.frame(Message="No Buy/Sell crossover events occurred in selected range.")); tail(s,12)},striped=TRUE,bordered=TRUE)
}
shinyApp(ui=ui,server=server)
