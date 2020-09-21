using System;
using System.Collections.Generic;
using System.Linq;

using Mommosoft.ExpertSystem;

namespace AutoICU.AI.HypokalemiaV1
{
    // The Reflection class is used by AutoIcuAI to identify the capabilities of the AI module.
    public class Reflection
    {
        public string version = "1.0.0";
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

        public override DecisionResult IdentifyTreatment()
        {
            List<Treatment> treatments = new List<Treatment>();
            List<Action> actions = new List<Action>();
            List<Reason> reasons = new List<Reason>();

            string currentGFR = "";
            string GFRTrend = "unknown";
            bool Dialysis = false;

            double latest = testData.Offsets().Min();
            List<Value> GfrValues = testData.Values("gfr");
            double slope = 0;
            if (GfrValues.Count() == 0)
            {
                Action action = new Action();
                action.text = "Please provide at least one GFR value.";
                actions.Add(action);
            }
            else if (GfrValues.Count() > 1)
            {
                List<double> weights = new List<double>();
                List<double> offsets = new List<double>();
                List<double> values = new List<double>();
                foreach (Value value in GfrValues)
                {
                    double days = (value.offset - latest) / 86400;
                    double new_weight = Math.Pow((1 - test_trend_decay_per_day), (double)value.value);
                    offsets.Add(value.offset);
                    values.Add((double)value.value);
                    weights.Add(Math.Max(0.125, new_weight));
                }
                double[] lsrResults = LeastSquaresWeightedBestFitLine1(offsets.ToArray(), values.ToArray(), weights.ToArray());
                //intercept = results[0];
                slope = -lsrResults[1];
                currentGFR = testData.Value("gfr", latest).value.ToString();
                if (currentGFR == "-1")
                {
                    currentGFR = "";
                    GFRTrend = "";
                    Dialysis = true;
                }
                else if (GfrValues.Count > 1 && currentGFR != "")
                {
                    // double diff = (y_values[0] - intercept) / intercept;
                    GFRTrend = "stable";
                    if (slope / (double)testData.Value("gfr", latest).value > 0.1)
                    {
                        GFRTrend = "increasing";
                    }
                    if (slope / (double)testData.Value("gfr", latest).value < -0.1)
                    {
                        GFRTrend = "decreasing";
                    }
                }
            }
            else // Single GFR value
            {
                if (GfrValues.Count() > 0)
                {
                    currentGFR = testData.Value("gfr", latest).value.ToString();
                }
                if (currentGFR == "-1")
                {
                    currentGFR = "";
                    GFRTrend = "";
                    Dialysis = true;
                }
                else
                {
                    GFRTrend = "stable";
                }
            }

            Value urineProduction = testData.Value("urine production", latest);
            double urineProductionValue = 0;
            if (urineProduction.value == null || !(urineProduction.value is double))
            {
                Action action = new Action();
                action.text = "Please provide urine production as a number.";
                actions.Add(action);
            }
            else
            {
                urineProductionValue = (double)urineProduction.value;
            }
            Value potassium = testData.Value("potassium", latest);
            double potassiumValue = 0;
            if (potassium.value == null || !(potassium.value is double))
            {
                Action action = new Action();
                action.text = "Please provide potassium as a number.";
                actions.Add(action);
            }
            else
            {
                potassiumValue = (double)potassium.value;
            }
            Value magnesium = testData.Value("magnesium", latest);
            double magnesiumValue = 0;
            if (magnesium.value == null || !(magnesium.value is double))
            {
                Action action = new Action();
                action.text = "Please provide magnesium as a number.";
                actions.Add(action);
            }
            else
            {
                magnesiumValue = (double)magnesium.value;
            }
            Value phosphorus = testData.Value("phosphorus", latest);
            double phosphorusValue = 0;
            if (phosphorus.value == null || !(phosphorus.value is double))
            {
                Action action = new Action();
                action.text = "Please provide phosphorus as a number.";
                actions.Add(action);
            }
            else
            {
                phosphorusValue = (double)phosphorus.value;
            }
            Value calcium = testData.Value("calcium, ionized", latest);
            double calciumValue = 0;
            if (calcium.value == null || !(calcium.value is double))
            {
                Action action = new Action();
                action.text = "Please provide calcium as a number.";
                actions.Add(action);
            }
            else
            {
                calciumValue = (double)calcium.value;
            }
            Value diarrhea = testData.Value("diarrhea", latest);
            string diarrheaValue = diarrhea.value as string;
            if (diarrheaValue == null || diarrheaValue == "")
            {
                diarrheaValue = "X";
            }
            else
            {
                diarrheaValue = diarrheaValue.ToUpper();
                if (diarrheaValue[0] != 'N' && diarrheaValue[0] != 'Y')
                {
                    Action action = new Action();
                    action.text = "Please provide diarrhea as Yes, Y, No or N.";
                    actions.Add(action);
                }
                else
                {
                    diarrheaValue = diarrheaValue.Substring(0, 1);
                }
            }

            double recentKCL = 0;
            int recentKCLtreatements = 0;

            List<Value> kclTreatments = treatmentData.Values("kcl");
            foreach(Value kclTreatment in kclTreatments)
            {
                if (kclTreatment.offset <= 2 * 86400) // 2 days
                {
                    recentKCL += (double)kclTreatment.value;
                    recentKCLtreatements++;
                }
            }

            if (actions.Count == 0) // no errors
            {
                // Clear old values
                //clips.Eval("(clear)");
                //clips.Load("Hypokalemia.clp");
                //clips.Eval("(reset)"); // load facts from deffacts constructs.
                clips.Clear();
                clips.Load("Hypokalemia.clp");
                clips.Reset(); // load facts from deffacts constructs.

                // Set values in CLIPS
                clips.AssertString("(diagnosis (patient " + patientID + ") (name HYPOKALEMIA))");
                if (Dialysis)
                {
                    clips.AssertString("(test-value (patient " + patientID + ") (name Dialysis) (value TRUE))");
                }
                if (currentGFR != "")
                {
                    clips.AssertString("(test-value (patient " + patientID + ") (name GFR) (value " + currentGFR + "))");
                }
                if (GFRTrend != "")
                {
                    clips.AssertString("(test-value (patient " + patientID + ") (name GFR-trend) (value " + GFRTrend.ToUpper() + "))");
                }
                if (urineProduction != null)
                {
                    clips.AssertString("(test-value (patient " + patientID + ") (name Urine-production) (value " + urineProductionValue + "))");
                }
                if (potassium != null)
                {
                    clips.AssertString("(test-value (patient " + patientID + ") (name Potassium) (value " + potassiumValue + "))");
                }

                if (magnesium != null)
                {
                    clips.AssertString("(test-value (patient " + patientID + ") (name Magnesium) (value " + magnesiumValue + "))");
                }
                if (phosphorus != null)
                {
                    clips.AssertString("(test-value (patient " + patientID + ") (name Phosphorus) (value " + phosphorusValue + "))");
                }
                if (calcium != null)
                {
                    clips.AssertString("(test-value (patient " + patientID + ") (name Calcium) (value " + calciumValue + "))");
                }
                if (diarrhea != null)
                {
                    clips.AssertString("(test-value (patient " + patientID + ") (name Diarrhea) (value " + diarrheaValue + "))");
                }

                Value EnteralRoute = testData.Value("enteralroute", latest);
                if (EnteralRoute != null && (bool)EnteralRoute.value)
                {
                    clips.AssertString("(available-routes (patient " + patientID + ") (type ENTERAL))");
                }
                Value CentralRoute = testData.Value("centralroute", latest);
                if (CentralRoute != null && (bool)CentralRoute.value)
                {
                    clips.AssertString("(available-routes (patient " + patientID + ") (type CENTRAL-IV))");
                }
                Value PeripheralRoute = testData.Value("peripheralroute", latest);
                if (PeripheralRoute != null && (bool)PeripheralRoute.value)
                {
                    clips.AssertString("(available-routes (patient " + patientID + ") (type PERIPHERAL-IV))");
                }

                clips.AssertString("(test-value (patient " + patientID + ") (name Recent-KCL) (value " + recentKCL + "))");
                clips.AssertString("(test-value (patient " + patientID + ") (name Recent-KCL-Treatements) (value " + recentKCLtreatements + "))");

                //clips.Reset();
                clips.Run();

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
                    }
                    else
                    {
                        IntegerValue tempValue = (IntegerValue)tempIndex;
                        treatment.index = (int)(tempValue);
                    }
                    treatment.type = (string)((SymbolValue)fv.GetFactSlot("type"));
                    treatment.med = (string)((SymbolValue)fv.GetFactSlot("med"));
                    PrimitiveValue quantitySlot = fv.GetFactSlot("quantity");
                    if (quantitySlot is FloatValue)
                    {
                        treatment.quantity = (double)((FloatValue)quantitySlot);
                    }
                    else
                    {
                        treatment.quantity = (int)((IntegerValue)quantitySlot);
                    }
                    treatment.units = (string)((SymbolValue)fv.GetFactSlot("units"));
                    treatment.route = (string)((SymbolValue)fv.GetFactSlot("route"));
                    treatments.Add(treatment);
                }

                MultifieldValue actionFacts = clips.Eval("(find-all-facts ((?action action)) TRUE)") as MultifieldValue;
                foreach (FactAddressValue fv in actionFacts)
                {
                    Action action = new Action();
                    action.text = ((SymbolValue)fv.GetFactSlot("text")).ToString().Replace("GFR-trend", "Previous GFR");
                    actions.Add(action);
                }

                MultifieldValue reasonFacts = clips.Eval("(find-all-facts ((?reason reason)) TRUE)") as MultifieldValue;
                foreach (FactAddressValue fv in reasonFacts)
                {
                    Reason reason = new Reason(
                        (int)((IntegerValue)fv.GetFactSlot("level")),
                        ((SymbolValue)fv.GetFactSlot("rule")).ToString(),
                        ((SymbolValue)fv.GetFactSlot("text")).ToString().Replace("GFR-trend", "Previous GFR"));
                    reasons.Add(reason);
                }
            }

            return new DecisionResult(treatments, actions, reasons);
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

        public override List<string> DataValues()
        {
            throw new NotImplementedException();
        }

        private double test_trend_decay_per_day = 0.067; // Halflife of 10 days
    }
}
