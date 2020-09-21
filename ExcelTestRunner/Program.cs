using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using CsvHelper;
using CsvHelper.Configuration;

using AutoICU.AI;
using AutoICU.AI.HypokalemiaV1;

namespace ExcelTestRunner
{
    class Program
    {
        static void Main(string[] args)
        {
            //  Read the csv file for inputs
            using (StreamWriter outputFile = File.CreateText("testcaseResults.csv"))
            using (StreamReader reader = new StreamReader("testcasesComplete.csv"))
            using (CsvReader csv = new CsvReader(reader, CultureInfo.InvariantCulture))
            {
                Testcase.WriteHeaders(outputFile);
                csv.Configuration.BadDataFound = null;
                csv.Configuration.HasHeaderRecord = false; // Can't use headers since CsvHelper fails on headers with spaces and/or slash (e.g. "Scr 1 mg/dl")
                csv.Configuration.RegisterClassMap<TestcaseMap>();

                csv.Read();
                while (csv.Read()) //  Foreach row
                {
                    Testcase testcase = csv.GetRecord<Testcase>();
                    //  Run Hypokalemia Module
                    RunTestcase(testcase);
                    //  Add Treatments, Actions and Reasons to the testcase
                    //  Write testcase to a new csv file.
                    testcase.Write(outputFile);
                }
            }
        }

        private static void RunTestcase(Testcase testcase)
        {
            ValueTable testData = new ValueTable(testcase.KDate);
            ValueTable treatmentData = new ValueTable(testcase.KDate);

            double temp;
            double temp2;
            if (testcase.Dialysis.ToLower().StartsWith("y"))
            {
                testData.SetValue("GFR", -1, "", testcase.KDate);
            }
            else
            {
                if (testcase.Creatinine1 != "")
                {
                    double GFR1 = GetGFR(testcase.Creatinine1, testcase.DOB, testcase.KDate, testcase.Gender, testcase.Ethnicity);
                    if (GFR1 >= 0)
                    {
                        testData.SetValue("gfr", GFR1, "ml/min", testcase.SCr1date);
                    }
                }
                if (testcase.Creatinine2 != "")
                {
                    double GFR2 = GetGFR(testcase.Creatinine2, testcase.DOB, testcase.KDate, testcase.Gender, testcase.Ethnicity);
                    if (GFR2 >= 0)
                    {
                        testData.SetValue("gfr", GFR2, "ml/min", testcase.SCr2date);
                    }
                }
            }
            if (double.TryParse(testcase.UrineProduction, out temp))
            {
                testData.SetValue("urine production", temp, "ml/kg/hr", testcase.UrineDate);
            }
            if (double.TryParse(testcase.Potassium, out temp))
            {
                testData.SetValue("potassium", temp, "mEq/l", testcase.KDate);
            }
            if (double.TryParse(testcase.Magnesium, out temp))
            {
                testData.SetValue("magnesium", temp, "mg/dl", testcase.MgDate);
            }
            if (double.TryParse(testcase.Phosphorus, out temp))
            {
                testData.SetValue("phosphorus", temp, "mg/dl", testcase.PhosDate);
            }
            if (testcase.CaType == "ionized" && double.TryParse(testcase.Calcium, out temp))
            {
                testData.SetValue("calcium, ionized", temp, "mg/dl", testcase.CaDate);
            }
            if (testcase.CaType == "total" && double.TryParse(testcase.Calcium, out temp) && double.TryParse(testcase.Albumin, out temp2))
            {
                if (temp2 < 4.0)
                {
                    temp += 0.8 * (4.0 - temp2);
                }
                testData.SetValue("calcium, ionized", temp, "mg/dl", testcase.CaDate);
            }
            testData.SetValue("diarrhea", testcase.Diarrhea.ToLower().StartsWith("y") ? "Yes" : "No", "", testcase.KDate);

            testData.SetValue("EnteralRoute", true, "", testcase.KDate);
            testData.SetValue("CentralRoute", true, "", testcase.KDate);
            testData.SetValue("PeripheralRoute", true, "", testcase.KDate);

            if (double.TryParse(testcase.Supplement48hrs, out temp))
            {
                treatmentData.SetValue("kcl", temp, "mEq", testcase.KDate.AddDays(-1));
            }


            Intervention hypokalemia = new Module(testcase.PatientID, testData, treatmentData);
            DecisionResult results = hypokalemia.IdentifyTreatment();

            testcase.Treatments = results.treatments.OrderBy(t => t.index)
                .Select(t => t.index + ": " + t.type + ": " + t.med
                    + " " + t.quantity + " " + t.units + " " + t.route).ToList();
            testcase.Actions = results.actions.Select(a => a.text.Trim('"')).ToList(); ;
            testcase.Reasons = results.reasons.Select(r => r.level + ": " + r.text.Trim('"')).ToList();
        }

        private static double GetGFR(string Creatinine, string DOB, DateTime CrDate, string Gender, string Ethnicity)
        {
            double GFR = -1;
            double SCr = 0;
            DateTime dob;
            if (double.TryParse(Creatinine, out SCr)
                && DateTime.TryParse(DOB, out dob))
            {
                int age = CrDate.Year - dob.Year + (CrDate.DayOfYear < dob.DayOfYear ? -1 : 0);
                if (Gender.StartsWith("M"))
                {
                    GFR = 141 * Math.Pow(Math.Min(SCr / 0.9, 1), -0.411) * Math.Pow(Math.Max(SCr / 0.9, 1), -1.209) * Math.Pow(0.993, age);
                }
                else
                {
                    GFR = 141 * Math.Pow(Math.Min(SCr / 0.7, 1), -0.329) * Math.Pow(Math.Max(SCr / 0.7, 1), -1.209) * Math.Pow(0.993, age) * 1.018;
                }
                if (Ethnicity.ToLower().Contains("african american"))
                {
                    GFR *= 1.159;
                }
            }
            return GFR;
        }
    }

    public class Testcase
    {
        public string PatientID;
        public string Gender;
        public string DOB;
        public string Ethnicity;
        public string Creatinine1 = "";
        public DateTime SCr1date;
        public string Creatinine2 = "";
        public DateTime SCr2date;
        public string CCR = "";
        public DateTime CCRdate;
        public string Dialysis;
        public string UrineProduction = "";
        public DateTime UrineDate;
        public string Weight = "";
        public DateTime WtDate;
        public string Potassium = "";
        public DateTime KDate;
        public string Phosphorus = "";
        public DateTime PhosDate;
        public string Calcium = "";
        public DateTime CaDate;
        public string CaType = "";
        public string Magnesium = "";
        public DateTime MgDate;
        public string Diarrhea;
        public string Albumin = "";
        public DateTime AlbDate;
        public string Supplement24hrs = "";
        public string Supplement48hrs = "";
        public string Supplements = ""; // Not the same as when creating the excel testcases
        public List<string> Treatments = new List<string>();
        public List<string> Actions = new List<string>();
        public List<string> Reasons = new List<string>();

        public Testcase() // Needed by CsvHelper
        {
        }

        public Testcase(string PatientID, string Gender, string DOB, string Ethnicity, string Dialysis, string Diarrhea)
        {
            this.PatientID = PatientID;
            this.Gender = Gender;
            this.DOB = DOB;
            this.Ethnicity = Ethnicity;
            this.Dialysis = Dialysis;
            this.Diarrhea = Diarrhea;
        }

        public Testcase(Testcase other)
        {
            PatientID = other.PatientID;
            Gender = other.Gender;
            DOB = other.DOB;
            Ethnicity = other.Ethnicity;
            Creatinine1 = other.Creatinine1;
            SCr1date = other.SCr1date;
            Creatinine2 = other.Creatinine2;
            SCr2date = other.SCr2date;
            CCR = other.CCR;
            CCRdate = other.CCRdate;
            Dialysis = other.Dialysis;
            UrineProduction = other.UrineProduction;
            UrineDate = other.UrineDate;
            Weight = other.Weight;
            WtDate = other.WtDate;
            Potassium = other.Potassium;
            KDate = other.KDate;
            Phosphorus = other.Phosphorus;
            PhosDate = other.PhosDate;
            Calcium = other.Calcium;
            CaDate = other.CaDate;
            CaType = other.CaType;
            Magnesium = other.Magnesium;
            MgDate = other.MgDate;
            Diarrhea = other.Diarrhea;
            Albumin = other.Albumin;
            AlbDate = other.AlbDate;
            Supplement24hrs = other.Supplement24hrs;
            Supplement48hrs = other.Supplement48hrs;
            Supplements = other.Supplements;
        }

        public static string[] headers = new string[] {
                "PatientID", "Timestamp", "Gender", "DOB", "Ethnicity",
                "SCr 1 mg/dl", "SCr 1 date/time", "SCr 2 mg/dl", "SCr 2 date/time",
                "CCR ml/min", "CCR Date", "Dialysis", "Urine Prod ml/kg/hr", "Urine date/time",
                "Weight kg", "Wt date/time", "Potassium mEq/l", "K date/time",
                "Phosphate mg/dl", "Phos date/time", "Ca mg/dl", "Ca date/time", "Ca type",
                "Magnesium mg/dl", "Mg date/time", "Diarrhea", "Albumin g/dl", "Albumin date/time",
                "24 supplements", "48 supplements", "Supplements", "Treatments", "Actions", "Reasons"
            };

        public static void WriteHeaders(StreamWriter outputFile)
        {
            foreach (string header in headers)
            {
                if (header != "PatientID")
                {
                    outputFile.Write(",");
                }
                outputFile.Write(header);
            }
            outputFile.WriteLine();
        }

        public void Write(StreamWriter outputFile)
        {
            outputFile.Write(PatientID + ",");
            outputFile.Write(KDate + ",");
            outputFile.Write(Gender + ",");
            outputFile.Write(DOB + ",");
            outputFile.Write(Ethnicity + ",");
            outputFile.Write(Creatinine1 + ",");
            outputFile.Write(SCr1date + ",");
            outputFile.Write(Creatinine2 + ",");
            outputFile.Write(SCr2date + ",");
            outputFile.Write(CCR + ",");
            outputFile.Write(CCRdate + ",");
            outputFile.Write(Dialysis + ",");
            outputFile.Write(UrineProduction + ",");
            outputFile.Write(UrineDate + ",");
            outputFile.Write(Weight + ",");
            outputFile.Write(WtDate + ",");
            outputFile.Write(Potassium + ",");
            outputFile.Write(KDate + ",");
            outputFile.Write(Phosphorus + ",");
            outputFile.Write(PhosDate + ",");
            outputFile.Write(Calcium + ",");
            outputFile.Write(CaDate + ",");
            outputFile.Write(CaType + ",");
            outputFile.Write(Magnesium + ",");
            outputFile.Write(MgDate + ",");
            outputFile.Write(Diarrhea + ",");
            outputFile.Write(Albumin + ",");
            outputFile.Write(AlbDate + ",");
            outputFile.Write(Supplement24hrs + ",");
            outputFile.Write(Supplement48hrs + ",");
            outputFile.Write(Supplements + ",");
            outputFile.Write("\"" + string.Join("\n", Treatments).Replace("\"", "\"\"") + "\",");
            outputFile.Write("\"" + string.Join("\n", Actions).Replace("\"", "\"\"") + "\",");
            outputFile.Write("\"" + string.Join("\n", Reasons).Replace("\"", "\"\"") + "\",");
            outputFile.WriteLine();
        }
    }

    public sealed class TestcaseMap : ClassMap<Testcase>
    {
        public TestcaseMap()
        {
            Map(m => m.PatientID).Index(0);
            // Timestamp (not used)
            Map(m => m.Gender).Index(2);
            Map(m => m.DOB).Index(3);
            Map(m => m.Ethnicity).Index(4);
            Map(m => m.Creatinine1).Index(5);
            Map(m => m.SCr1date).Index(6).ConvertUsing(row => DateTime.ParseExact(row.GetField(6), "dd/MM/yyyy H:mm:ss", CultureInfo.InvariantCulture));
            // Map(m => m.SCr1date).Index(6).TypeConverterOption.Format("dd/MM/yyyy HH:mm"); // Does not work!
            Map(m => m.Creatinine2).Index(7);
            Map(m => m.SCr2date).Index(8).ConvertUsing(row => DateTime.ParseExact(row.GetField(8), "dd/MM/yyyy H:mm:ss", CultureInfo.InvariantCulture));
            Map(m => m.CCR).Index(9);
            Map(m => m.CCRdate).Index(10).ConvertUsing(row => DateTime.ParseExact(row.GetField(10), "dd/MM/yyyy H:mm:ss", CultureInfo.InvariantCulture));
            Map(m => m.Dialysis).Index(11);
            Map(m => m.UrineProduction).Index(12);
            Map(m => m.UrineDate).Index(13).ConvertUsing(row => DateTime.ParseExact(row.GetField(13), "dd/MM/yyyy H:mm:ss", CultureInfo.InvariantCulture));
            Map(m => m.Weight).Index(14);
            Map(m => m.WtDate).Index(15).ConvertUsing(row => DateTime.ParseExact(row.GetField(15), "dd/MM/yyyy H:mm:ss", CultureInfo.InvariantCulture));
            Map(m => m.Potassium).Index(16);
            Map(m => m.KDate).Index(17).ConvertUsing(row => DateTime.ParseExact(row.GetField(17), "dd/MM/yyyy H:mm:ss", CultureInfo.InvariantCulture));
            Map(m => m.Phosphorus).Index(18);
            Map(m => m.PhosDate).Index(19).ConvertUsing(row => DateTime.ParseExact(row.GetField(19), "dd/MM/yyyy H:mm:ss", CultureInfo.InvariantCulture));
            Map(m => m.Calcium).Index(20);
            Map(m => m.CaDate).Index(21).ConvertUsing(row => DateTime.ParseExact(row.GetField(21), "dd/MM/yyyy H:mm:ss", CultureInfo.InvariantCulture));
            Map(m => m.CaType).Index(22);
            Map(m => m.Magnesium).Index(23);
            Map(m => m.MgDate).Index(24).ConvertUsing(row => DateTime.ParseExact(row.GetField(24), "dd/MM/yyyy H:mm:ss", CultureInfo.InvariantCulture));
            Map(m => m.Diarrhea).Index(25);
            Map(m => m.Albumin).Index(26);
            Map(m => m.AlbDate).Index(27).ConvertUsing(row => DateTime.ParseExact(row.GetField(27), "dd/MM/yyyy H:mm:ss", CultureInfo.InvariantCulture));
            Map(m => m.Supplement24hrs).Index(28);
            Map(m => m.Supplement48hrs).Index(29);
            Map(m => m.Supplements).Index(30);
        }
    }
}