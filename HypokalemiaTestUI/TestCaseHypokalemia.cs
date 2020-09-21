using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using AutoICU.AI;

namespace TestUI
{
    public class TestcaseHypokalemia
    {
        // ToDo: Change the Intervention class to use a single set of inputs
        //          intead of separte test data and treatment data.

        AutoICU.AI.ValueTable testData = new ValueTable();
        DecisionResult results = new DecisionResult();

        private static string[] hypokalemiaTreatments = new string[]
        {
            "potassium bicarbonate eff","k-lor","potassium ch","*nf* potassium chloride","potassiu",
            "potassium chloride replacement (oncology)","potassium chloride (powder)","potassium chloride",
            "potassium chl","potassium phosphate","micro-k","potassium",
            "potassium citrate","neo*po*potassium chloride","pota","k-dur","potass","potas",
            "neo*po*potassium phosphate"
        };

        // Create a testcase for hypokalemia from a generic MIMIC III testcase
        TestcaseHypokalemia(Testcase testcase)
        {
            // Find the first prescription for a potassium suplement
            DateTime treatmentTimestamp = DateTime.UtcNow;

            // Store the first prescription as the expected result for analysis
            // Find the inputs for the hypokalemia algorithm

            // GFR (ml/min)
            // Get the age
            double age = testcase.age(treatmentTimestamp);
            if(age >= 0)
            {
                GenericEvent firstCreatinineEvent = testcase.GetLatestLabEvent(new string[] { "creatinine" }, treatmentTimestamp);
                GenericEvent secondCreatinineEvent = null;
                if (firstCreatinineEvent != null)
                {
                    double GFR1 = GFR(firstCreatinineEvent.valueNum, age, testcase.ethnicity, testcase.gender);
                    if(GFR1 > 0.0)
                    {
                        testData.SetValue("gfr", GFR1, "mL/min/1.73 m2", firstCreatinineEvent.chartDateTime);
                        double GFR2 = -1;
                        secondCreatinineEvent = testcase.GetLatestLabEvent(new string[] { "creatinine" }, firstCreatinineEvent.chartDateTime);
                        if (secondCreatinineEvent != null)
                        {
                            GFR2 = GFR(secondCreatinineEvent.valueNum, age, testcase.ethnicity, testcase.gender);
                            if (GFR2 >= 0.0)
                            {
                                testData.SetValue("gfr", GFR2, "mL/min/1.73 m2", secondCreatinineEvent.chartDateTime);
                            }
                        }
                    }
                }
                else
                {
                    results.actions.Add(new AutoICU.AI.Action("Creatinine missing."));
                    results.reasons.Add(new AutoICU.AI.Reason(0, "Required Input", "Creatinine is required to calculate the estimated GFR."));
                    return;
                }
            }
            else
            {
                results.actions.Add(new AutoICU.AI.Action("Age missing."));
                results.reasons.Add(new AutoICU.AI.Reason(0, "Required Input", "Age is required to calculate the estimated GFR."));
                return;
            }

            // Urine Production (ml/kg/hr)
            // Get the last weight
            GenericEvent weightEvent = testcase.GetLatestEvent(new string[] { "weight" }, treatmentTimestamp);
            if(weightEvent != null)
            {
                double weight = weightEvent.valueNum;

                DateTime previousDate = treatmentTimestamp.AddDays(-1);
                DateTime firstTimestamp = treatmentTimestamp;
                DateTime lastTimestamp = firstTimestamp;
                double urineProduction = -1;
                GenericEvent genericEvent = testcase.GetLatestOutputEvent(new string[] { "foley" }, firstTimestamp);
                while (genericEvent != null && genericEvent.valueNum >= 0 && genericEvent.chartDateTime >= previousDate) 
                {
                    firstTimestamp = genericEvent.chartDateTime;
                    if(urineProduction < 0.0)
                    {
                        lastTimestamp = firstTimestamp;
                        urineProduction = 0.0;
                    }
                    urineProduction += genericEvent.valueNum;
                    genericEvent = testcase.GetLatestOutputEvent(new string[] { "foley" }, firstTimestamp);
                }
                if (firstTimestamp != lastTimestamp)
                {
                    urineProduction -= genericEvent.valueNum;
                    urineProduction = urineProduction / (lastTimestamp - firstTimestamp).Minutes / 60 / weight;
                    testData.SetValue("urine production", urineProduction, "ml/kg/hr", lastTimestamp);
                }
            }
            else
            {
                results.actions.Add(new AutoICU.AI.Action("Weight missing."));
                results.reasons.Add(new AutoICU.AI.Reason(0, "Required Input", "Weight is required to calculate the Urine Production."));
                return;
            }

            // Potassium (mEq/l)
            GenericEvent labEvent = testcase.GetLatestLabEvent(new string[] { "potassium" }, treatmentTimestamp);
            if(labEvent != null)
            {
                testData.SetValue("potassium", labEvent.valueNum, "mEq/l", labEvent.chartDateTime);
            }
            else
            {
                results.actions.Add(new AutoICU.AI.Action("Potassium missing."));
                results.reasons.Add(new AutoICU.AI.Reason(0, "Required Input", "Potassium is required to determine the recommended treatment."));
                return;
            }

            //values.Add(new ValueSet("Magnesium (mg/dl)"));
            labEvent = testcase.GetLatestLabEvent(new string[] { "magnesium" }, treatmentTimestamp);
            if (labEvent != null)
            {
                testData.SetValue("magnesium", labEvent.valueNum, "mg/dl", labEvent.chartDateTime);
            }

            //values.Add(new ValueSet("Phosphorus (mg/dl)"));
            labEvent = testcase.GetLatestLabEvent(new string[] { "phosphorus" }, treatmentTimestamp);
            if (labEvent != null)
            {
                testData.SetValue("phosphorus", labEvent.valueNum, "mg/dl", labEvent.chartDateTime);
            }

            //values.Add(new ValueSet("Calcium, Ionized (mg/dl)"));
            labEvent = testcase.GetLatestLabEvent(new string[] { "calcium, ionized" }, treatmentTimestamp);
            if (labEvent != null)
            {
                testData.SetValue("calcium, ionized", labEvent.valueNum, "mg/dl", labEvent.chartDateTime);
            }
            else
            {
                labEvent = testcase.GetLatestLabEvent(new string[] { "calcium, total" }, treatmentTimestamp);
                if (labEvent != null)
                {
                    double totalCalcium = labEvent.valueNum;
                    labEvent = testcase.GetLatestLabEvent(new string[] { "albumin" }, treatmentTimestamp);
                    if (labEvent != null)
                    {

                        testData.SetValue("calcium, corrected", totalCalcium + 0.8 * (4.0 - Math.Min(4.0, labEvent.valueNum)), 
                            "mg/dl", labEvent.chartDateTime);
                    }
                }
            }

            //values.Add(new ValueSet("Diarrhea (Y/N)"));
            labEvent = testcase.GetLatestLabEvent(new string[] { "diarrhea" }, treatmentTimestamp);
            if (labEvent != null)
            {
                testData.SetValue("diarrhea", "Y", "", treatmentTimestamp);
            }
            else
            {
                testData.SetValue("diarrhea", "N", "", treatmentTimestamp);
            }

            //treatments.Add(new ValueSet("KCL (mEq)"));
            DateTime earliestTreatmentDate = treatmentTimestamp.AddDays(-2);
            DateTime latestTimestamp = treatmentTimestamp;
            List<GenericEvent> prescriptionEvents = testcase.GetLatestPrescriptionEvents(hypokalemiaTreatments, earliestTreatmentDate, treatmentTimestamp);
            foreach(GenericEvent prescriptionEvent in prescriptionEvents)
            {
                testData.SetValue("kcl", prescriptionEvent.valueNum, prescriptionEvent.valueUnits, prescriptionEvent.chartDateTime);
            }
        }

        public static double GFR(double creatinine, double age, string ethnicity, string gender)
        {
            double GFR = -1;
            if (creatinine >= 0.0)
            {
                // eGFR = 141 x min(SCr / κ, 1)^α x max(SCr / κ, 1)^-1.209 x 0.993^Age x 1.018[if female] x 1.159[if Black]  
                if (gender.ToLower().Contains("f"))
                {
                    GFR = 141 * 1.018;
                    if (creatinine <= 0.7)
                    {
                        GFR *= Math.Pow(creatinine / 0.7, -0.329);
                    }
                    else
                    {
                        GFR *= Math.Pow(creatinine / 0.7, -1.209);
                    }
                }
                else
                {
                    GFR = 141;
                    if (creatinine <= 0.9)
                    {
                        GFR *= Math.Pow(creatinine / 0.9, -0.411);
                    }
                    else
                    {
                        GFR *= Math.Pow(creatinine / 0.9, -1.209);
                    }
                }
                GFR *= Math.Pow(0.993, age);
                if (ethnicity.ToLower().Contains("african"))
                {
                    GFR *= 1.159;
                }
            }
            return GFR;      
        }
    }
}
