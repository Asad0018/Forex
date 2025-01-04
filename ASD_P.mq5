// +------------------------------------------------------------------+
// |                                                        ASD_P.mq5 |
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
input int Position = 2; // 1:top-left 2:top-right 3:down-left 4:down-right
input double Midnight_Balance = 14443.07; // Balance at the beginning of today: 
input double Start_Balance    = 15000; // Initial deposit: 
input int Daily_Drawdown_Percentage = 5; // Daily Drawdown Percentage:
input int Maximum_Drawdown_Percentage = 12; // Maximum Drawdown Percentage:
input double MDL_Percentage = 55; // MDL Limitation Percentage:

// +------------------------------------------------------------------+
// | Maximum drawdown (MDD) & Daily drawdown (DDD)                    |
// +------------------------------------------------------------------+
double MDD = Start_Balance    * (100 - Maximum_Drawdown_Percentage)/100;
double DDD = Midnight_Balance * (100 - Daily_Drawdown_Percentage)  /100;

// +------------------------------------------------------------------+
// | Custom indicator initialization function                         |
// +------------------------------------------------------------------+
int OnInit()
{
   int chart_width  = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS,  0);
   int chart_height = ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0);
   int x_distance = 10;   // X distance from the left of the chart
   int y_distance = 118;      // Y starting position
   int line_spacing = 17; // Space between lines
   if( Position == 1 )                 y_distance = 188;
   if( Position == 2 || Position == 4) x_distance = chart_width - 185;
   if( Position == 3 || Position == 4) y_distance = chart_height - 130;
   
   // Create a button for closing the indicator
   string button_name = "CloseButton";
   if (!ObjectCreate(0, button_name, OBJ_BUTTON, 0, 0, 0))
   {
      Print("Failed to create button. Error: ", GetLastError());
      return INIT_FAILED;
   }
   
   // Set button properties
   ObjectSetInteger(0, button_name, OBJPROP_XDISTANCE, x_distance);          // X position (10 pixels from the left)
   ObjectSetInteger(0, button_name, OBJPROP_YDISTANCE, y_distance);          // Y position (10 pixels from the top)
   ObjectSetInteger(0, button_name, OBJPROP_XSIZE, 50);             // Width of the button
   ObjectSetInteger(0, button_name, OBJPROP_YSIZE, 20);              // Height of the button
   ObjectSetString (0, button_name, OBJPROP_TEXT, "close");           // Button text
   ObjectSetInteger(0, button_name, OBJPROP_CORNER, CORNER_LEFT_UPPER); // Button position anchor
   ObjectSetInteger(0, button_name, OBJPROP_COLOR, clrRed);          // Button background color
   ObjectSetInteger(0, button_name, OBJPROP_FONTSIZE, 10);           // Font size
   ObjectSetInteger(0, button_name, OBJPROP_BORDER_TYPE, BORDER_RAISED); // Button border type

   return(INIT_SUCCEEDED);
}
 void OnChartEvent(const int id,         // Event ID
                  const long &lparam,   // Event parameter
                  const double &dparam, // Event parameter
                  const string &sparam) // Event string parameter
{
   if (id == CHARTEVENT_OBJECT_CLICK && sparam == "CloseButton")
   {
      // Remove the indicator from the chart when the button is clicked
      ChartIndicatorDelete(0, 0, "ASD_P");
   }
}

// +------------------------------------------------------------------+
// | Custom indicator deinitialization function                       |
// +------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Delete the button when the indicator is removed
   ObjectDelete(0, "CloseButton");
   
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
// Starting positions for X and Y
   int chart_width  = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS,  0);
   int chart_height = ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0);
   int x_distance = 10;   // X distance from the left of the chart
   int y_start = 10;      // Y starting position
   int line_spacing = 17; // Space between lines
   if( Position == 1 )                 y_start = 80;
   if( Position == 2 || Position == 4) x_distance = chart_width - 185;
   if( Position == 3 || Position == 4) y_start = chart_height - 110;
   
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
double Available_Margin = ( (AccountInfoDouble(ACCOUNT_EQUITY)*0.55) - 
   (AccountInfoDouble(ACCOUNT_MARGIN)*(AccountInfoInteger(ACCOUNT_LEVERAGE)/100)) );
double XAU_MDL  = Available_Margin /  SymbolInfoDouble(Symbol(), SYMBOL_ASK);
double EURx_MDL = Available_Margin / (SymbolInfoDouble("EURUSD", SYMBOL_ASK)*1000);
double GBPx_MDL = Available_Margin / (SymbolInfoDouble("GBPUSD", SYMBOL_ASK)*1000);
double AUDx_MDL = Available_Margin / (SymbolInfoDouble("AUDUSD", SYMBOL_ASK)*1000);
double NZDx_MDL = Available_Margin / (SymbolInfoDouble("NZDUSD", SYMBOL_ASK)*1000);
double USDx_MDL = Available_Margin / 1000;
double CADx_MDL = Available_Margin / (1000/SymbolInfoDouble("USDCAD", SYMBOL_ASK));
double CHFx_MDL = Available_Margin / (1000/SymbolInfoDouble("USDCHF", SYMBOL_ASK));

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
   double risk1 = floor(AccountInfoDouble(ACCOUNT_BALANCE) - MinBalance);
   double risk2 = AccountInfoDouble(ACCOUNT_EQUITY) - MinBalance;
   double DPL = AccountInfoDouble(ACCOUNT_EQUITY) - Midnight_Balance;
   
   // ---Convert to String---:
   string risk1Text =      DoubleToString(risk1,0);
   string risk2Text =      DoubleToString(risk2,2);
   string MDLText =        DoubleToString(MDL,3);
   string MinBalanceText = DoubleToString(MinBalance,2);
   string DPLText =        DoubleToString(DPL,2);
   string PVText =         DoubleToString(PV,3);
   if (PV == 10) PVText =  DoubleToString(PV,0);
    
string words[6] = { "Available:    " + risk1Text + " $", 
                    "Floating:      " + risk2Text + " $", 
                    "MDL:             " + MDLText + " Lot", 
                    "Daily P/L:     " + DPLText + " $", 
                    "Borderline: " + MinBalanceText + " $", 
                    "Pip Value:   " + PVText
                  };  
   
   color colors[6] = {clrLime, clrLime, clrLime, clrLime, clrYellow, clrAqua};
   if (risk1 < 0){
      colors[0] = clrRed;
      risk1 = 0;
      }
   if (risk2 < 0) colors[1] = clrRed;
   if (MDL < 0) colors[2] = clrRed;
   if (DPL < 0) colors[3] = clrOrange;
   
   for (int i = 0; i < ArraySize(words); i++) 
   {
      string label_name = "Label" + IntegerToString(i);  // Unique object name for each word

      // Create a text label
      if (!ObjectCreate(0, label_name, OBJ_LABEL, 0, 0, 0)) 
      {
         Print("Error creating object: ", GetLastError());
         return(INIT_FAILED);
      }

      // Set text for the label
      ObjectSetString(0, label_name, OBJPROP_TEXT, words[i]);

      // Set font properties (font size, type, and color)
      ObjectSetInteger(0, label_name, OBJPROP_FONTSIZE, 12); // Font size
      ObjectSetInteger(0, label_name, OBJPROP_COLOR, colors[i]); // Font color
      ObjectSetInteger(0, label_name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER); // Align to top-left
      ObjectSetString(0, label_name, OBJPROP_FONT, "Arial Bold"); // Font type (Arial Bold)
      
      // Set the position of the label
      ObjectSetInteger(0, label_name, OBJPROP_XDISTANCE, x_distance);       // Horizontal distance
      ObjectSetInteger(0, label_name, OBJPROP_YDISTANCE, y_start + i * line_spacing); // Vertical position
   }

   return(rates_total);
}
