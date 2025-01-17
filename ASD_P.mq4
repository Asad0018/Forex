// +------------------------------------------------------------------+
// |                                                        ASD_P.mq4 |
// |                                                   Asad Khademian |
// |                                             https://t.me/Asad018 |
// +------------------------------------------------------------------+
#property copyright "Asad Khademian"
#property link      "https://t.me/Asad018"
#property version   "1.02"
#property indicator_chart_window  // Display indicator in the main chart window

// +------------------------------------------------------------------+
// | Inputs                                                           |
// +------------------------------------------------------------------+
input int Position = 2;                   // 1:top-left 2:top-right 3:down-left 4:down-right
input double Midnight_Balance = 0;
input double Start_Balance    = 15000;
input int Daily_Drawdown_Percentage = 5;
input int Maximum_Drawdown_Percentage = 12;
input double MDL_Percentage = 55;
// Default value of midnight balance = current balance:
double MB(){
   double a;
   if (Midnight_Balance == 0) a = AccountBalance();
      return a;
   return Midnight_Balance;
}
const double MB = MB();
// +------------------------------------------------------------------+
// | Maximum drawdown (MDD) & Daily drawdown (DDD)                    |
// +------------------------------------------------------------------+
double MDD = Start_Balance * (100 - Maximum_Drawdown_Percentage)/100;
double DDD = MB * (100 - Daily_Drawdown_Percentage)/100;

// +------------------------------------------------------------------+
// | Custom indicator initialization function                         |
// +------------------------------------------------------------------+
int OnInit()
{
   int chart_width  = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS,  0);
   int chart_height = ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0);
   // Starting positions for X and Y
   int x_distance = 10;   // X distance from the left of the chart
   int y_start = 10;      // Y starting position
   int line_spacing = 17; // Space between lines
   if( Position == 1 )                 y_start = 80;
   if( Position == 2 || Position == 4) x_distance = chart_width - 185;
   if( Position == 3 || Position == 4) y_start = chart_height - 110;
   
   for (int i = 0; i < 6; i++) {
   
        // Create labels for each counter
        string label_name = "Label" + IntegerToString(i);
        if (!ObjectCreate(0, label_name, OBJ_LABEL, 0, 0, 0)) {
            Print("Error creating object: ", GetLastError());
            return(INIT_FAILED);
        }

        // Set initial text for each label
        ObjectSetText(label_name, IntegerToString(i), 24, "Arial", clrRed);
        
        // Set the position for each label in the top-right corner
        ObjectSetInteger(0, label_name, OBJPROP_XDISTANCE, x_distance);
        ObjectSetInteger(0, label_name, OBJPROP_YDISTANCE, y_start + i * 17);
    }

   return(INIT_SUCCEEDED);
}


// +------------------------------------------------------------------+
// | Custom indicator deinitialization function                       |
// +------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Delete the objects when the indicator is removed
   for (int i = 0; i < 6; i++) {
      string label_name = "Label" + IntegerToString(i);
      ObjectDelete(0, label_name);
   }
}

// +------------------------------------------------------------------+
// | Custom indicator iteration function                              |
// +------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
// +------------------------------------------------------------------+
// | Boolean variables                                                |
// +------------------------------------------------------------------+
bool XU = Symbol() == "XAUUSD" ,
// --- EUR based pair currencies:
     EG = Symbol() == "EURGBP" , EA = Symbol() == "EURAUD" ,
     EN = Symbol() == "EURNZD" , EU = Symbol() == "EURUSD" ,
     ECa= Symbol() == "EURCAD" , ECh= Symbol() == "EURCHF" , 
     EJ = Symbol() == "EURJPY" ,
// --- GBP based currencies:
     GA = Symbol() == "GBPAUD" , GN = Symbol() == "GBPNZD" ,
     GU = Symbol() == "GBPUSD" , GCa= Symbol() == "GBPCAD" ,
     GCh= Symbol() == "GBPCHF" , GJ = Symbol() == "GBPJPY" ,
// --- AUD based currencies:
     AN = Symbol() == "AUDNZD" , AU = Symbol() == "AUDUSD" ,
     ACa= Symbol() == "AUDCAD" , ACh= Symbol() == "AUDCHF" ,
     AJ = Symbol() == "AUDJPY" ,
// ---NZD based currencies:
     NU = Symbol() == "NZDUSD" , NCa= Symbol() == "NZDCAD" ,
     NCh= Symbol() == "NZDCHF" , NJ = Symbol() == "NZDJPY" ,
// --- USD based currencies:
     UCa= Symbol() == "USDCAD" , UCh= Symbol() == "USDCHF" ,
     UJ = Symbol() == "USDJPY" ,
// --- CAD based currencies:
     CaCh=Symbol() == "CADCHF" , CaJ= Symbol() == "CADJPY" ,
// --- CHF based currency:
     ChJ= Symbol() == "CHFJPY" ;

// +------------------------------------------------------------------+
// | Max Deposit Load (MDL) limitation calculation                    |
// +------------------------------------------------------------------+
double Available_Margin = ( (AccountEquity()* (MDL_Percentage / 100)) - (AccountMargin()*(AccountLeverage()/100)) ),
       XAU_MDL  = Available_Margin / Ask,
       EURx_MDL = Available_Margin / (SymbolInfoDouble("EURUSD", SYMBOL_ASK)*1000),
       GBPx_MDL = Available_Margin / (SymbolInfoDouble("GBPUSD", SYMBOL_ASK)*1000),
       AUDx_MDL = Available_Margin / (SymbolInfoDouble("AUDUSD", SYMBOL_ASK)*1000),
       NZDx_MDL = Available_Margin / (SymbolInfoDouble("NZDUSD", SYMBOL_ASK)*1000),
       USDx_MDL = Available_Margin / 1000,
       CADx_MDL = Available_Margin / (1000/SymbolInfoDouble("USDCAD", SYMBOL_ASK)),
       CHFx_MDL = Available_Margin / (1000/SymbolInfoDouble("USDCHF", SYMBOL_ASK));
   
   double MDL;
   if      ( XU )                                        MDL = XAU_MDL ;
   else if ( EG  || EA || EN || EU || ECa || ECh || EJ ) MDL = EURx_MDL;
   else if ( GA  || GN || GU || GCa|| GCh || GJ )        MDL = GBPx_MDL;
   else if ( AN  || AU || ACa|| ACh|| AJ )               MDL = AUDx_MDL;
   else if ( NU  || NCa|| NCh|| NJ )                     MDL = NZDx_MDL;
   else if ( UCa || UCh|| UJ )                           MDL = USDx_MDL;
   else if ( CaCh|| CaJ )                                MDL = CADx_MDL;
   else if ( ChJ )                                       MDL = CHFx_MDL;
   
// +------------------------------------------------------------------+
// | Pip Value calculation                                            |
// +------------------------------------------------------------------+
double xGBP_PV = SymbolInfoDouble("GBPUSD", SYMBOL_ASK)*10 ,
       xAUD_PV = SymbolInfoDouble("AUDUSD", SYMBOL_ASK)*10 ,
       xNZD_PV = SymbolInfoDouble("NZDUSD", SYMBOL_ASK)*10 ,
       xUSD_PV = 10 ,
       xCAD_PV = 10   / SymbolInfoDouble("USDCAD", SYMBOL_ASK) ,
       xCHF_PV = 10   / SymbolInfoDouble("USDCHF", SYMBOL_ASK) ,
       xJPY_PV = 1000 / SymbolInfoDouble("USDJPY", SYMBOL_ASK) ;
   
   double PV;
   if      ( EG )                                      PV = xGBP_PV;
   else if ( EA || GA )                                PV = xAUD_PV;
   else if ( EN || GN || AN )                          PV = xNZD_PV;
   else if ( EU || GU || AU || NU || XU )              PV = xUSD_PV;
   else if ( ECa|| GCa|| ACa|| NCa|| UCa )             PV = xCAD_PV;
   else if ( ECh|| GCh|| ACh|| NCh|| UCh|| CaCh )      PV = xCHF_PV;
   else if ( EJ || GJ || AJ || NJ || UJ || CaJ|| ChJ ) PV = xJPY_PV;
// --------------------- Calculations ended ---------------------------------
// --------------------------------------------------------------------------
// --------------------------------------------------------------------------

   // -----Variables------
   double MinBalance = DDD;   
   if (MDD > DDD) MinBalance = MDD;
   double risk1 = floor(AccountBalance() - MinBalance);
   double risk2 = AccountEquity() - MinBalance;
   double DPL = AccountEquity() - MB;
   
   // ------Colors------
   color a = clrLime;
   color b = clrLime;
   color c = clrLime;
   color d = clrLime;

   if (risk1 < 0){
      a = clrRed;
      risk1 = 0;
      }
   if (risk2 < 0) b = clrRed;
   if (MDL < 0) c = clrRed;
   if (DPL < 0) d = clrOrange;
      
   // ---Convert to String---:
   string risk1Text =      DoubleToString(risk1,0);
   string risk2Text =      DoubleToString(risk2,2);
   string MDLText =        DoubleToString(MDL,3);
   string MinBalanceText = DoubleToString(MinBalance,2);
   string DPLText =        DoubleToString(DPL,2);
   string PVText =         DoubleToString(PV,3);
   if (PV == 10) PVText =  DoubleToString(PV,0);
    
   // ---Show the results---:
   ObjectSetText("Label0","Available:    "    + risk1Text      + " $",   12, "Arial Bold", a);
   ObjectSetText("Label1","Floating:      "   + risk2Text      + " $",   12, "Arial Bold", b);
   ObjectSetText("Label2","MDL:             " + MDLText        + " Lot", 12, "Arial Bold", c);
   ObjectSetText("Label3","Daily P/L:     "   + DPLText        + " $",   12, "Arial Bold", d);
   ObjectSetText("Label4","Borderline: "      + MinBalanceText + " $",   12, "Arial Bold", clrYellow);
   ObjectSetText("Label5","Pip Value:   "     + PVText         + " $",   12, "Arial Bold", clrAqua);

   return(rates_total);
}
