using System;
using System.Collections.Generic;
using System.Linq;

using Mommosoft.ExpertSystem;

namespace AutoICU.AI.HypokalemiaV2
{
    // The Reflection class is used by AutoIcuAI to identify the capabilities of the AI module.
    public class Reflection
    {
        public string version = "2.0.0";
        public string interventionName = "Hypokalemia";
        public bool diagnose = false;
        public bool treatment = true;
        public List<Tuple<string, string>> dependencies = new List<Tuple<string, string>>();
    }

    public class Module : Intervention
    {
        private Mommosoft.ExpertSystem.Environment clips;

        public Module(string patient, ValueTable testData, ValueTable treatmentData) 
            : base(patient, testData, treatmentData)
        {
            clips = new Mommosoft.ExpertSystem.Environment();
        }

        // 
        public override bool Diagnose()
        {
            return true;
        }

        public override List<string> DataValues()
        {
            List<string> dataValues = new List<string>();
            // Step 1
            List<Value> Values = testData.Values("potassium");
            if (Values.Count > 0)
            {
                string potassiumValue = Values[0].ToString();
                //(data-value (name potassium) (patient 123456) (value 3.5))
                dataValues.Add("(data-value (patient " + patientID + ") (name potassium) (value " + potassiumValue + "))");
            }

            // Step 2
            string Dialysis = "NO";
            Values = testData.Values("dialysis");
            if (Values.Count() > 0)
            {
                Dialysis = Values[0].ToString().ToUpper();
            }
            //(data-value (name dialysis) (patient 123456) (value NO))
            dataValues.Add("(data-value (patient " + patientID + ") (name dialysis) (value " + Dialysis + "))");

            // Step 3
            Values = testData.Values("gfr");
            double slope = 0;
            if (Values.Count() > 0)
            {
                string currentGFR = Values[0].ToString();
                //(data-value (name GFR) (patient 123456) (value 45))
                dataValues.Add("(data-value (patient " + patientID + ") (name GFR) (value " + currentGFR + "))");
            }

            string GFRTrend = "Unknown";
            if (Values.Count() > 1)
            {
                List<double> weights = new List<double>();
                List<double> offsets = new List<double>();
                List<double> values = new List<double>();
                foreach (Value value in Values)
                {
                    double days = value.offset / 86400;
                    offsets.Add(days);
                    values.Add((double)value.value);
                    double new_weight = Math.Pow((1 - test_trend_decay_per_day), days);
                    weights.Add(Math.Max(0.125, new_weight));
                }
                double[] lsrResults = LeastSquaresWeightedBestFitLine1(offsets.ToArray(), values.ToArray(), weights.ToArray());
                //intercept = results[0];
                slope = -lsrResults[1];
                // double diff = (y_values[0] - intercept) / intercept;
                GFRTrend = "Stable";
                if (slope / (double)Values[0].value > 0.1)
                {
                    GFRTrend = "Improving";
                }
                if (slope / (double)Values[0].value < -0.1)
                {
                    GFRTrend = "Worsening";
                    //(data-value (name GFR-trend) (patient 123456) (value Stable))
                }
            }
            dataValues.Add("(data-value (patient " + patientID + ") (name GFR-trend) (value " + GFRTrend + "))");

            string urineProduction = "Unknown";
            Values = testData.Values("urine production");
            if (Values.Count() > 0)
            {
                double urineProductionValue = (double)Values[0].value;
                if (urineProductionValue > 0.5) urineProduction = "Normal";
                else if (urineProductionValue >= 0.4) urineProduction = "Marginal";
                else if (urineProductionValue >= 0.1) urineProduction = "Oliguric";
                else urineProduction = "Anuric";
            }
            dataValues.Add("(data-value (patient " + patientID + ") (name Urine-production) (value " + urineProduction + "))");

            // Step 4.
            string TTTstate = "NONE";
            Values = testData.Values("TTT-state");
            if (Values.Count() > 0)
            {
                TTTstate = Values[0].ToString().ToUpper();
            }
            dataValues.Add("(data-value (patient " + patientID + ") (name TTT-state) (value " + TTTstate + "))");

            string timeToRewarming = "over-4-hours";
            Values = testData.Values("time-to-rewarming");
            if (Values.Count() > 0)
            {
                timeToRewarming = Values[0].ToString();
            }
            dataValues.Add("(data-value (patient " + patientID + ") (name time-to-rewarming) (value " + timeToRewarming + "))");

            // Step 5.
            string pastLoopDiuretic = "NO";
            Values = testData.Values("past-loop-diuretic");
            if (Values.Count() > 0)
            {
                pastLoopDiuretic = Values[0].ToString().ToUpper();
            }
            dataValues.Add("(data-value (patient " + patientID + ") (name past-loop-diuretic) (value " + pastLoopDiuretic + "))");

            // Step 6.
            string diarrheaValue = "NO";
            Values = testData.Values("past-diarrhea");
            if (Values.Count() > 0)
            {
                diarrheaValue = Values[0].ToString().ToUpper();
            }
            dataValues.Add("(data-value (patient " + patientID + ") (name past-diarrhea) (value " + diarrheaValue + "))");

            // Step 7.
            string PastSupplementation = "NONE";
            Values = treatmentData.Values("supplement24hrs");
            if (Values.Count() > 0 && Values[0].value is double)
            {
                double value = (double)Values[0].value;
                if (value == 0) PastSupplementation = "NONE";
                else if (value <= 30) PastSupplementation = "20mEq";
                else if (value <= 50) PastSupplementation = "40mEq";
                else PastSupplementation = "60mEq";
            }
            dataValues.Add("(data-value (patient " + patientID + ") (name Past-Supplementation) (value " + PastSupplementation + "))");

            string PotassiumTrend = "Stable";
            Values = testData.Values("potassium");
            if (Values.Count() > 1)
            {
                if ((double)Values[0].value - (double)Values[1].value >= 0.3)
                {
                    PotassiumTrend = "Increasing";
                }
                if ((double)Values[0].value - (double)Values[1].value <= -0.3)
                {
                    PotassiumTrend = "Decreasing";
                }
            }
            dataValues.Add("(data-value (patient " + patientID + ") (name Potassium-trend) (value " + PotassiumTrend + "))");

            // Step 8.
            Values = testData.Values("potassium");
            string potassiumRange = null;
            if (Values.Count > 0)
            {
                double potassium = (double)Values[0].value;
                if (3.8 <= potassium) potassiumRange = "HIGH";
                else if (3.4 <= potassium && potassium < 3.8) potassiumRange = "MED";
                else if (3.0 <= potassium && potassium < 3.4) potassiumRange = "LOW";
                else potassiumRange = "VLOW";
                dataValues.Add("(data-value (patient " + patientID + ") (name potassium-range) (value " + potassiumRange + "))");
            }

            // Step 9.
            // Removed by Tzvi

            // Step 10.
            string phosphorusRange = "UNKNOWN";
            Values = testData.Values("phosphorus");
            if (Values.Count > 0)
            {
                double potassium = (double)Values[0].value;
                if (2.0 <= potassium) phosphorusRange = "HIGH";
                else if (1.5 < potassium && potassium < 2.0) phosphorusRange = "MED";
                else phosphorusRange = "LOW";
            }
            dataValues.Add("(data-value (patient " + patientID + ") (name phosphorus-range) (value " + phosphorusRange + "))");

            // Step 11.
            string calciumValue = null;
            Values = testData.Values("calcium, ionized");
            if (Values.Count() > 0)
            {
                calciumValue = Values[0].ToString();
                dataValues.Add("(data-value (patient " + patientID + ") (name calcium) (value " + calciumValue + "))");
            }

            return dataValues;
        }

        public override DecisionResult IdentifyTreatment()
        {
            List<Treatment> treatments = new List<Treatment>();
            List<Action> actions = new List<Action>();
            List<Reason> reasons = new List<Reason>();

            //// Step 1
            //string potassiumValue = null;

            //List<Value> Values = testData.Values("potassium");
            //if (Values.Count > 0)
            //{
            //    potassiumValue = Values[0].ToString();
            //}

            //// Step 2
            //string Dialysis = "NO";

            //Values = testData.Values("dialysis");
            //if (Values.Count() > 0)
            //{
            //    Dialysis = Values[0].ToString().ToUpper();
            //}

            //// Step 3
            //string currentGFR = "";
            //string GFRTrend = "Unknown";

            //Values = testData.Values("gfr");
            //double slope = 0;
            //if (Values.Count() > 0)
            //{
            //    currentGFR = Values[0].ToString();
            //}
            //if (Values.Count() > 1)
            //{
            //    List<double> weights = new List<double>();
            //    List<double> offsets = new List<double>();
            //    List<double> values = new List<double>();
            //    foreach (Value value in Values)
            //    {
            //        double days = value.offset / 86400;
            //        offsets.Add(days);
            //        values.Add((double)value.value);
            //        double new_weight = Math.Pow((1 - test_trend_decay_per_day), days);
            //        weights.Add(Math.Max(0.125, new_weight));
            //    }
            //    double[] lsrResults = LeastSquaresWeightedBestFitLine1(offsets.ToArray(), values.ToArray(), weights.ToArray());
            //    //intercept = results[0];
            //    slope = -lsrResults[1];
            //    // double diff = (y_values[0] - intercept) / intercept;
            //    GFRTrend = "Stable";
            //    if (slope / (double)Values[0].value > 0.1)
            //    {
            //        GFRTrend = "Improving";
            //    }
            //    if (slope / (double)Values[0].value < -0.1)
            //    {
            //        GFRTrend = "Worsening";
            //    }
            //}

            //Values = testData.Values("urine production");
            //string urineProduction = null;
            //if (Values.Count() > 0)
            //{
            //    double urineProductionValue = (double)Values[0].value;
            //    if (urineProductionValue > 0.5) urineProduction = "Normal";
            //    else if (urineProductionValue >= 0.4) urineProduction = "Marginal";
            //    else if (urineProductionValue >= 0.1) urineProduction = "Oliguric";
            //    else urineProduction = "Anuric";
            //}
            //else
            //{
            //    urineProduction = "Unknown";
            //}

            //// Step 4.
            //string TTTstate = "NONE";
            //string timeToRewarming = "over-4-hours";

            //Values = testData.Values("TTT-state");
            //if (Values.Count() > 0)
            //{
            //    TTTstate = Values[0].ToString().ToUpper();
            //}

            //Values = testData.Values("time-to-rewarming");
            //if (Values.Count() > 0)
            //{
            //    timeToRewarming = Values[0].ToString();
            //}

            //// Step 5.
            //string pastLoopDiuretic = "NO";

            //Values = testData.Values("past-loop-diuretic");
            //if (Values.Count() > 0)
            //{
            //    pastLoopDiuretic = Values[0].ToString().ToUpper();
            //}

            //// Step 6.
            //string diarrheaValue = "NO";

            //Values = testData.Values("past-diarrhea");
            //if (Values.Count() > 0)
            //{
            //    diarrheaValue = Values[0].ToString().ToUpper();
            //}

            //// Step 7.
            //string PastSupplementation = "NONE";
            //string PotassiumTrend = "Stable";

            //Values = treatmentData.Values("supplement24hrs");
            //if (Values.Count() > 0 && Values[0].ToString() != "0")
            //{
            //    if(Values[0].value is double)
            //    {
            //        double value = (double)Values[0].value;
            //        if (value == 0) PastSupplementation = "NONE";
            //        else if(value <= 30) PastSupplementation = "20mEq";
            //        else if (value <= 50) PastSupplementation = "40mEq";
            //        else PastSupplementation = "60mEq";
            //    }
            //}

            //Values = testData.Values("potassium");
            //if (Values.Count() > 1)
            //{
            //    if((double)Values[0].value - (double)Values[1].value >= 0.3)
            //    {
            //        PotassiumTrend = "Increasing";
            //    }
            //    if ((double)Values[0].value - (double)Values[1].value <= -0.3)
            //    {
            //        PotassiumTrend = "Decreasing";
            //    }
            //}

            //// Step 8.
            //Values = testData.Values("potassium");
            //string potassiumRange = null;
            //if (Values.Count > 0)
            //{
            //    double potassium = (double)Values[0].value;
            //    if (3.8 <= potassium) potassiumRange = "HIGH";
            //    else if (3.4 <= potassium && potassium < 3.8) potassiumRange = "MED";
            //    else if (3.0 <= potassium && potassium < 3.4) potassiumRange = "LOW";
            //    else potassiumRange = "VLOW";
            //}

            //// Step 9.
            //// Removed by Tzvi

            //// Step 10.
            //string phosphorusRange = "UNKNOWN";

            //Values = testData.Values("phosphorus");
            //if (Values.Count > 0)
            //{
            //    double potassium = (double)Values[0].value;
            //    if (2.0 <= potassium) phosphorusRange = "HIGH";
            //    else if (1.5 < potassium && potassium < 2.0) phosphorusRange = "MED";
            //    else phosphorusRange = "LOW";
            //}

            //// Step 11.
            //string calciumValue = "1.0";

            //Values = testData.Values("calcium, ionized");
            //if (Values.Count() > 0)
            //{
            //    calciumValue = Values[0].ToString();
            //}

            //if (actions.Count == 0) // no errors
            //{
                // Clear old values
                //clips.Eval("(clear)");
                //clips.Load("Hypokalemia.clp");
                //clips.Eval("(reset)"); // load facts from deffacts constructs.
                clips.Clear();
                clips.Load("HypokalemiaV2.clp");
                clips.Reset(); // load facts from deffacts constructs.

            // Set values in CLIPS

            List<string> dataValues = DataValues();
            foreach(string dataValue in dataValues)
            {
                clips.AssertString(dataValue);
            }
////                clips.AssertString("(diagnosis (patient " + patientID + ") (name Hypokalemia))");
//                if (Dialysis != "")
//                {
//                    //(data-value (name dialysis) (patient 123456) (value NO))
//                    string dataValue = "(data-value (patient " + patientID + ") (name dialysis) (value " + Dialysis + "))";
//                    clips.AssertString(dataValue);
//                }
//                if (currentGFR != "")
//                {
//                    //(data-value (name GFR) (patient 123456) (value 45))
//                    string dataValue = "(data-value (patient " + patientID + ") (name GFR) (value " + currentGFR + "))";
//                    clips.AssertString(dataValue);
//                }
//                if (GFRTrend != "")
//                {
//                    //(data-value (name GFR-trend) (patient 123456) (value Stable))
//                    string dataValue = "(data-value (patient " + patientID + ") (name GFR-trend) (value " + GFRTrend + "))";
//                    clips.AssertString(dataValue);
//                }
//                if (urineProduction != null)
//                {
//                    //(data-value (name Urine-production) (patient 123456) (value Normal))
//                    string dataValue = "(data-value (patient " + patientID + ") (name Urine-production) (value " + urineProduction + "))";
//                    clips.AssertString(dataValue);
//                }
//                if (potassiumValue != null)
//                {
//                    //(data-value (name potassium) (patient 123456) (value 3.5))
//                    string dataValue = "(data-value (patient " + patientID + ") (name potassium) (value " + potassiumValue + "))";
//                    clips.AssertString(dataValue);
//                }
//                if (potassiumRange != null)
//                {
//                    //(data-value (name potassium) (patient 123456) (value 3.5))
//                    string dataValue = "(data-value (patient " + patientID + ") (name potassium-range) (value " + potassiumRange + "))";
//                    clips.AssertString(dataValue);
//                }
//                if (phosphorusRange != null)
//                {
//                    //(data-value (name phosphorus) (patient 123456) (value 2.5))
//                    string dataValue = "(data-value (patient " + patientID + ") (name phosphorus-range) (value " + phosphorusRange + "))";
//                    clips.AssertString(dataValue);
//                }
//                if (calciumValue != null)
//                {
//                    //(data-value (name calcium) (patient 123456) (value 2.0))
//                    string dataValue = "(data-value (patient " + patientID + ") (name calcium) (value " + calciumValue + "))";
//                    clips.AssertString(dataValue);
//                }
//                if (diarrheaValue != null)
//                {
//                    //(data-value (name past-diarrhea) (patient 123456) (value NO))
//                    string dataValue = "(data-value (patient " + patientID + ") (name past-diarrhea) (value " + diarrheaValue + "))";
//                    clips.AssertString(dataValue);
//                }
//                if (TTTstate != null)
//                {
//                    //(data-value (name TTT-state) (patient 123456) (value COOLING))
//                    string dataValue = "(data-value (patient " + patientID + ") (name TTT-state) (value " + TTTstate + "))";
//                    clips.AssertString(dataValue);
//                }
//                if (timeToRewarming != null)
//                {
//                    //(data-value (name time-to-rewarming) (patient 123456) (value over-4-hours))
//                    string dataValue = "(data-value (patient " + patientID + ") (name time-to-rewarming) (value " + timeToRewarming + "))";
//                    clips.AssertString(dataValue);
//                }
//                if (pastLoopDiuretic != null)
//                {
//                    //(data-value (name past-loop-diuretic) (patient 123456) (value NO))
//                    string dataValue = "(data-value (patient " + patientID + ") (name past-loop-diuretic) (value " + pastLoopDiuretic + "))";
//                    clips.AssertString(dataValue);
//                }
//                if (PastSupplementation != null)
//                {
//                    //(data-value (name Past-Supplementation) (patient 123456) (value NONE))
//                    string dataValue = "(data-value (patient " + patientID + ") (name Past-Supplementation) (value " + PastSupplementation + "))";
//                    clips.AssertString(dataValue);
//                }
//                if (PotassiumTrend != null)
//                {
//                    //(data-value (name Potassium-trend) (patient 123456) (value Stable))
//                    string dataValue = "(data-value (patient " + patientID + ") (name Potassium-trend) (value " + PotassiumTrend + "))";
//                    clips.AssertString(dataValue);
//                }

                clips.AssertString("(state (patient " + patientID + ") (name Step-1))");

                clips.Run();

                MultifieldValue stateFacts = clips.Eval("(find-all-facts ((?fact state)) TRUE)") as MultifieldValue;
                foreach (FactAddressValue fv in stateFacts)
                {
                    string name = ((SymbolValue)fv.GetFactSlot("name"));
                }

                // Get values from CLIPS
                MultifieldValue treatmentFacts = clips.Eval("(find-all-facts ((?treatment treatment)) TRUE)") as MultifieldValue;
                foreach (FactAddressValue fv in treatmentFacts)
                {
                    Treatment treatment = new Treatment();
                    //treatment.index = (int)((NumberValue)fv.GetFactSlot("index")).GetIntegerValue();
                    //treatment.type = ((LexemeValue)fv.GetFactSlot("type")).GetLexemeValue();
                    //treatment.med = ((LexemeValue)fv.GetFactSlot("med")).GetLexemeValue();
                    //treatment.quantity = ((NumberValue)fv.GetFactSlot("quantity")).GetFloatValue();
                    //treatment.units = ((LexemeValue)fv.GetFactSlot("units")).GetLexemeValue();
                    //treatment.route = ((LexemeValue)fv.GetFactSlot("route")).GetLexemeValue();
                    object tempIndex = fv.GetFactSlot("index");
                    if (tempIndex is FloatValue)
                    {
                        FloatValue tempValue = (FloatValue)tempIndex;
                        treatment.index = (float)(tempValue);
                        treatment.type = (string)((SymbolValue)fv.GetFactSlot("type"));
                    }
                    else if(tempIndex is IntegerValue)
                    {
                        IntegerValue tempValue = (IntegerValue)tempIndex;
                        treatment.index = (int)(tempValue);
                        treatment.type = (string)((SymbolValue)fv.GetFactSlot("type"));
                    }
                    else
                    {
                        treatment.type = tempIndex.ToString();
                    }
                    //treatment.med = (string)((SymbolValue)fv.GetFactSlot("med"));
                    //PrimitiveValue quantitySlot = fv.GetFactSlot("quantity");
                    //if (quantitySlot is FloatValue)
                    //{
                    //    treatment.quantity = (double)((FloatValue)quantitySlot);
                    //}
                    //else
                    //{
                    //    treatment.quantity = (int)((IntegerValue)quantitySlot);
                    //}
                    //treatment.units = (string)((SymbolValue)fv.GetFactSlot("units"));
                    treatment.route = ((SymbolValue)fv.GetFactSlot("routes"));
                    treatments.Add(treatment);
                }

                MultifieldValue actionFacts = clips.Eval("(find-all-facts ((?action action)) TRUE)") as MultifieldValue;
                foreach (FactAddressValue fv in actionFacts)
                {
                    Action action = new Action();
                    string actionText = ((SymbolValue)fv.GetFactSlot("text")).ToString();
                    if (!actions.Any(a => a.text == actionText))
                    {
                        action.text = actionText;
                        actions.Add(action);
                    }
                }

                MultifieldValue reasonFacts = clips.Eval("(find-all-facts ((?reason reason)) TRUE)") as MultifieldValue;
                foreach (FactAddressValue fv in reasonFacts)
                {
                    Reason reason = new Reason(
                        0, // (int)((IntegerValue)fv.GetFactSlot("level")),
                        ((SymbolValue)fv.GetFactSlot("rule")).ToString(),
                        ReplaceReasonText(((SymbolValue)fv.GetFactSlot("text")).ToString()));
                    reasons.Add(reason);
                }
            //}

            return new DecisionResult(treatments, actions, reasons);
        }

        private string ReplaceReasonText(string text)
        {
            if(text.Contains("potassium-range"))
            {
                if (text.Contains("VLOW")) return "Potassium is < 3.0";
                if (text.Contains("LOW")) return "Potassium is >= 3.0 and < 3.4";
                if (text.Contains("MED")) return "Potassium is >= 3.4 and < 3.8";
                if (text.Contains("HIGH")) return "Potassium is >= 3.8";
            }
            return text.Replace('-', ' ');
        }

        // Calculation of Weighted Least Squares for trend determination
        // Code from Numerical Methods, Algorithms and tools in C#, Chapter 15
        public static double[] LeastSquaresWeightedBestFitLine1(double[] x, double[] y, double[] w)
        {
            //Calculates equation of best-fit line using short cuts
            int n = x.Length;
            double wxMean = 0.0;
            double wyMean = 0.0;
            double wSum = 0.0;
            double wnumeratorSum = 0.0;
            double wdenominatorSum = 0.0;
            double bestfitYintercept = 0.0;
            double bestfitSlope = 0.0;
            double sigma = 0.0;
            double sumOfResidualsSquared = 0.0;

            //Calculates the sum of the weights w[i]
            for (int i = 0; i < n; i++)
            {
                wSum += w[i];
            }

            //Calculates the mean values for x and y arrays
            for (int i = 0; i < n; i++)
            {
                wxMean += w[i] * x[i] / wSum;
                wyMean += w[i] * y[i] / wSum;
            }

            //Calculates the numerator and denominator for best-fit slope
            for (int i = 0; i < n; i++)
            {
                wnumeratorSum += w[i] * y[i] * (x[i] - wxMean);
                wdenominatorSum += w[i] * x[i] * (x[i] - wxMean);
            }

            //Calculate the best-fit slope and y-intercept
            bestfitSlope = wnumeratorSum / wdenominatorSum;
            bestfitYintercept = wyMean - wxMean * bestfitSlope;

            //Calculate the best-fit standard deviation
            for (int i = 0; i < n; i++)
            {
                sumOfResidualsSquared += w[i] * (y[i] - bestfitYintercept - bestfitSlope * x[i]) * (y[i] - bestfitYintercept - bestfitSlope * x[i]);
            }
            sigma = Math.Sqrt(sumOfResidualsSquared / (n - 2));

            return new double[] { bestfitYintercept, bestfitSlope, sigma };
        }

        private double test_trend_decay_per_day = 0.067; // Halflife of 10 days
    }
}
