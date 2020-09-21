using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;

using CsvHelper;
using CsvHelper.Configuration;

using AutoICU.AI;
using AutoICU.AI.HypokalemiaV2;

namespace ExcelTestRunner
{
    class Program
    {
        static void Main(string[] args)
        {
            //  Read the csv file for inputs
            using (StreamWriter outputFile = File.CreateText("testcaseResults.csv"))
            using (StreamReader reader = new StreamReader("testcases.csv"))
            using (CsvReader csv = new CsvReader(reader, CultureInfo.InvariantCulture))
            {
                Testcase.WriteHeaders(outputFile);
                csv.Configuration.BadDataFound = null;
                csv.Configuration.HasHeaderRecord = false; // Can't use headers since CsvHelper fails on headers with spaces and/or slash (e.g. "Scr 1 mg/dl")
                csv.Configuration.RegisterClassMap<TestcaseMap>();

                csv.Read();
                while (csv.Read()) //  Foreach row
                {
                    string value;
                    List<string> values = new List<string>();
                    for (int i = 0; csv.TryGetField<string>(i, out value); i++)
                    {
                        values.Add(value);
                    }

                    //Testcase testcase = csv.GetRecord<Testcase>();
                    Testcase testcase = new Testcase(values);
                    //  Run Hypokalemia Module
                    //  Add Treatments, Actions and Reasons to the testcase
                    RunTestcase(testcase);
                    //  Write testcase to a new csv file.
                    testcase.WriteHypokalemiaV2(outputFile);
                }
            }
        }

        private static void RunTestcase(Testcase testcase)
        {
            ValueTable testData = new ValueTable(testcase.K1Date);
            ValueTable treatmentData = new ValueTable(testcase.K1Date);

            double temp;
            double temp2;

            //(data-value(name dialysis) (patient 123456) (value NO))
            if (testcase.Dialysis.ToLower().StartsWith("y"))
            {
                testData.SetValue("dialysis", "YES", "", testcase.K1Date);
            }
            else
            {
                testData.SetValue("dialysis", "NO", "", testcase.K1Date);
            }

            //(data-value(name GFR) (patient 123456) (value 45))
            if (testcase.Creatinine1 != "")
            {
                double GFR = GetGFR(testcase.Creatinine1, testcase.DOB, testcase.K1Date, testcase.Gender, testcase.Ethnicity);
                if (GFR >= 0)
                {
                    testData.SetValue("GFR", GFR, "ml/min", testcase.SCr1date);
                }
            }

            //GFR-trend is calculated in the module. (data-value(name GFR-trend) (patient 123456) (value Stable))
            if (testcase.Creatinine2 != "")
            {
                double GFR = GetGFR(testcase.Creatinine2, testcase.DOB, testcase.K1Date, testcase.Gender, testcase.Ethnicity);
                if (GFR >= 0)
                {
                    testData.SetValue("GFR", GFR, "ml/min", testcase.SCr2date);
                }
            }

            if (testcase.Creatinine3 != "")
            {
                double GFR = GetGFR(testcase.Creatinine3, testcase.DOB, testcase.K1Date, testcase.Gender, testcase.Ethnicity);
                if (GFR >= 0)
                {
                    testData.SetValue("GFR", GFR, "ml/min", testcase.SCr3date);
                }
            }

            if (double.TryParse(testcase.UrineProduction3hours, out temp))
            {
                testData.SetValue("urine production", temp, "ml/kg/hr", testcase.K1Date);
            }
            if (double.TryParse(testcase.Potassium1, out temp))
            {
                testData.SetValue("potassium", temp, "mEq/l", testcase.K1Date);
            }
            if (double.TryParse(testcase.Potassium2, out temp))
            {
                testData.SetValue("potassium", temp, "mEq/l", testcase.K2Date);
            }
            if (double.TryParse(testcase.Potassium3, out temp))
            {
                testData.SetValue("potassium", temp, "mEq/l", testcase.K3Date);
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
            testData.SetValue("past-loop-diuretic", testcase.LoopDiureticsDsc.ToLower().StartsWith("y") ? "Yes" : "No", "", testcase.K1Date);
            testData.SetValue("past-diarrhea", testcase.Diarrhea.ToLower().StartsWith("y") ? "Yes" : "No", "", testcase.K1Date);

            if (double.TryParse(testcase.Supplement24hrs, out temp))
            {
                treatmentData.SetValue("supplement24hrs", temp, "mEq", testcase.K1Date);
            }


            Intervention hypokalemia = new Module(testcase.PatientID, testData, treatmentData);
            DecisionResult results = hypokalemia.IdentifyTreatment();

            //testcase.Treatments = results.treatments.OrderBy(t => t.index)
            //    .Select(t => t.index + ": " + t.type + ": " + t.med
            //        + " " + t.quantity + " " + t.units + " " + t.route).ToList();
            if (results.treatments.Count == 1 && results.treatments[0].type.Contains("KCl")) // KCl only
            {
                testcase.Treatments = results.treatments.Select(t => t.type.Trim('"') + (t.route == "nil" ? "" : " " + t.route)).ToList();
            }
            else // Kphos and KCl, ignore routes
            {
                testcase.Treatments = results.treatments.Select(t => t.type.Trim('"')).ToList();
            }
            testcase.Actions = results.actions.Select(a => a.text.Trim('"')).ToList();
            testcase.Reasons = results.reasons.Select(r => r.text.Trim('"')).ToList();
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
        public long admissionID = -1;
        public bool newPotassiumValue = false;
        public string PatientID;
        public string Gender;
        public string DOB;
        public string Ethnicity;
        public string Creatinine1 = "";
        public DateTime SCr1date;
        public string Creatinine2 = "";
        public DateTime SCr2date;
        public string Creatinine3 = "";
        public DateTime SCr3date;
        public string CCR1 = "";
        public DateTime CCR1date;
        public string CCR2 = "";
        public DateTime CCR2date;
        public string CCR3 = "";
        public DateTime CCR3date;
        public string Dialysis;
        public string UrineProduction3hours = "";
        public string UrineProduction6hours = "";
        public string UrineProduction24hours = "";
        public string Weight = "";
        public DateTime WtDate;
        public string LoopDiureticsDsc = "No";
        public string Potassium1 = "";
        public DateTime K1Date;
        public string Potassium2 = "";
        public DateTime K2Date;
        public string Potassium3 = "";
        public DateTime K3Date;
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
        public List<string> Supplements = new List<string>();
        public List<string> Treatments;
        public List<string> Actions;
        public List<string> Reasons;

        public Testcase() // Needed by CsvHelper
        {
        }

        public Testcase(string PatientID, string Gender, string DOB, string Ethnicity,
            string Dialysis, string Diarrhea)
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
            admissionID = other.admissionID;
            newPotassiumValue = other.newPotassiumValue;
            PatientID = other.PatientID;
            Gender = other.Gender;
            DOB = other.DOB;
            Ethnicity = other.Ethnicity;
            Creatinine1 = other.Creatinine1;
            SCr1date = other.SCr1date;
            Creatinine2 = other.Creatinine2;
            SCr2date = other.SCr2date;
            Creatinine3 = other.Creatinine3;
            SCr3date = other.SCr3date;
            CCR1 = other.CCR1;
            CCR1date = other.CCR1date;
            CCR2 = other.CCR2;
            CCR2date = other.CCR2date;
            CCR3 = other.CCR3;
            CCR3date = other.CCR3date;
            Dialysis = other.Dialysis;
            UrineProduction3hours = other.UrineProduction3hours;
            UrineProduction6hours = other.UrineProduction6hours;
            UrineProduction24hours = other.UrineProduction24hours;
            Weight = other.Weight;
            WtDate = other.WtDate;
            LoopDiureticsDsc = other.LoopDiureticsDsc;
            Potassium1 = other.Potassium1;
            K1Date = other.K1Date;
            Potassium2 = other.Potassium2;
            K2Date = other.K2Date;
            Potassium3 = other.Potassium3;
            K3Date = other.K3Date;
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

        public static string[] HypokalemiaV2Headers = new string[] {
                "PatientID", "Notes", "Hypokalemia Data", "All Data",
                "K 1 mEq/l", "K 1 date/time",
                "K 2 mEq/l", "K 2 date/time", "K 2 hours",
                "K 3 mEq/l", "K 3 date/time", "K 3 hours",
                "Dialysis", "Gender", "Ethnicity", "DOB", "Age",
                "SCr 1 mg/dl", "SCr 1 date/time", "SCr 1 hours",
                "SCr 2 mg/dl", "SCr 2 date/time", "SCr 2 hours",
                "SCr 3 mg/dl", "SCr 3 date/time", "SCr 3 hours",
                "CCR 1 ml/min", "CCR 1 Date", "CCR 1 hours",
                "CCR 2 ml/min", "CCR 2 Date", "CCR 2 hours",
                "CCR 3 ml/min", "CCR 3 Date", "CCR 3 hours",
                "Urine Prod 3 hr ml/kg/hr", "Urine Prod 6 hr ml/kg/hr", "Urine Prod 24 hr ml/kg/hr",
                "Weight kg", "Wt date/time", "Wt hours", "Loop Diuretic Dsc", "Diarrhea Dsc",
                "24 supplements", "48 supplements",
                "Phosphate mg/dl", "Phos date/time", "Phosphate hours",
                "Ca mg/dl", "Ca date/time", "Ca hours", "Ca type",
                "Albumin g/dl", "Albumin date/time", "Albumin hours",
                "Mg mg/dl", "Mg date/time", "Mg hours", "",
                "Supplements Given", "", "Treatments", "Actions", "Reasons", "", "Valid", "Preferred Result8", "Discussion"
            };

        public static void WriteHeaders(StreamWriter outputFile, string[] headers = null)
        {
            if (headers == null)
            {
                headers = HypokalemiaV2Headers;
            }
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

        public void WriteHypokalemiaV2(StreamWriter outputFile)
        {
            outputFile.Write(PatientID + ",,,,");
            outputFile.Write(Potassium1 + ",");
            outputFile.Write(K1Date + ",");
            outputFile.Write(Potassium2 + ",");
            outputFile.Write(K2Date + ",");
            outputFile.Write(hours(K2Date) + ",");
            outputFile.Write(Potassium3 + ",");
            outputFile.Write(K3Date + ",");
            outputFile.Write(hours(K3Date) + ",");
            outputFile.Write(Dialysis + ",");
            outputFile.Write(Gender + ",");
            outputFile.Write(Ethnicity + ",");
            outputFile.Write(DOB + ",");
            outputFile.Write(age(K1Date) + ",");
            outputFile.Write(Creatinine1 + ",");
            outputFile.Write(SCr1date + ",");
            outputFile.Write(hours(SCr1date) + ",");
            outputFile.Write(Creatinine2 + ",");
            outputFile.Write(SCr2date + ",");
            outputFile.Write(hours(SCr2date) + ",");
            outputFile.Write(Creatinine3 + ",");
            outputFile.Write(SCr3date + ",");
            outputFile.Write(hours(SCr3date) + ",");
            outputFile.Write(CCR1 + ",");
            outputFile.Write(CCR1date + ",");
            outputFile.Write(hours(CCR1date) + ",");
            outputFile.Write(CCR2 + ",");
            outputFile.Write(CCR2date + ",");
            outputFile.Write(hours(CCR2date) + ",");
            outputFile.Write(CCR3 + ",");
            outputFile.Write(CCR3date + ",");
            outputFile.Write(hours(CCR3date) + ",");
            outputFile.Write(UrineProduction3hours + ",");
            outputFile.Write(UrineProduction6hours + ",");
            outputFile.Write(UrineProduction24hours + ",");
            outputFile.Write(Weight + ",");
            outputFile.Write(WtDate + ",");
            outputFile.Write(hours(WtDate) + ",");
            outputFile.Write(LoopDiureticsDsc + ",");
            outputFile.Write("No,"); // DiarrheaDsc + ",");
            outputFile.Write(Supplement24hrs + ",");
            outputFile.Write(Supplement48hrs + ",");
            outputFile.Write(Phosphorus + ",");
            outputFile.Write(PhosDate + ",");
            outputFile.Write(hours(PhosDate) + ",");
            outputFile.Write(Calcium + ",");
            outputFile.Write(CaDate + ",");
            outputFile.Write(hours(CaDate) + ",");
            outputFile.Write(CaType + ",");
            outputFile.Write(Albumin + ",");
            outputFile.Write(AlbDate + ",");
            outputFile.Write(hours(AlbDate) + ",");
            outputFile.Write(Magnesium + ",");
            outputFile.Write(MgDate + ",");
            outputFile.Write(hours(MgDate) + ",,");
            outputFile.Write(string.Join(":", Supplements) + ",");
            outputFile.Write(",\"" + string.Join("\n", Treatments).Replace("\"", "\"\"") + "\",");
            outputFile.Write("\"" + string.Join("\n", Actions).Replace("\"", "\"\"") + "\",");
            outputFile.Write("\"" + string.Join("\n", Reasons).Replace("\"", "\"\"") + "\"");
            outputFile.WriteLine();
        }

        public int age(DateTime timestamp)
        {
            int age = -1;
            DateTime dobTimestamp;
            if (DateTime.TryParse(DOB, out dobTimestamp))
            {
                age = timestamp.Year - dobTimestamp.Year;
                if (dobTimestamp.AddYears(age) > timestamp)
                {
                    age--; // Before this year's birthday
                }
            }
            return age;
        }

        public int hours(DateTime timestamp)
        {
            return (int)Math.Round((timestamp - K1Date).TotalHours);
        }

        public Testcase(List<string> values)
        {
            PatientID = values[0];
            // Notes Link (not used)    1
            // Hypokalemia Data Link (not used) 2
            // All Data Link (not used) 2
            Potassium1 = values[4];
            K1Date = getDateTime(values[5]);
            Potassium2 = values[6];
            K2Date = getDateTime(values[7]);
            // K 2 hours (not used)     8
            Potassium3 = values[9];
            K3Date = getDateTime(values[10]);
            // K 3 hours (not used)     11
            Dialysis = values[12];
            Gender = values[13];
            Ethnicity = values[14];
            DOB = values[15];
            // Age (not used)           16
            Creatinine1 = values[17];
            SCr1date = getDateTime(values[18]);
            // SCr 1 hours (not used)   19
            Creatinine2 = values[20];
            SCr2date = getDateTime(values[21]);
            // SCr 2 hours (not used)   22
            Creatinine3 = values[23];
            SCr3date = getDateTime(values[24]);
            // SCr 3 hours (not used)   25
            CCR1 = values[26];
            CCR1date = getDateTime(values[27]);
            // CCR 1 hours (not used)   28
            CCR2 = values[29];
            CCR2date = getDateTime(values[30]);
            // CCR 2 hours (not used)   31
            CCR3 = values[32];
            CCR3date = getDateTime(values[33]);
            // CCR 3 hours (not used)   34
            UrineProduction3hours = values[35];
            UrineProduction6hours = values[36];
            UrineProduction24hours = values[37];
            Weight = values[38];
            WtDate = getDateTime(values[39]);
            // Wt hours (not used)      40
            LoopDiureticsDsc = values[41];
            Diarrhea = values[42];
            Supplement24hrs = values[43];
            Supplement48hrs = values[44];
            Phosphorus = values[45];
            PhosDate = getDateTime(values[46]);
            // Phosphate hours (not used)   47
            Calcium = values[48];
            CaDate = getDateTime(values[49]);
            // Ca hours (not used)          50
            CaType = values[51];
            Albumin = values[52];
            AlbDate = getDateTime(values[53]);
            // Albumin hours (not used)     54
            Magnesium = values[55];
            MgDate = getDateTime(values[56]);
            // Mg hours (not used)          57
            // Skip spacer                  58
            Supplements = values[59].Split(new char[] { ':' }).ToList();
            // Skip spacer                  60
            Treatments = Regex.Split(values[61], "\r\n?|\n").ToList();
            Actions = Regex.Split(values[62], "\r\n?|\n").ToList();
            Reasons = Regex.Split(values[63], "\r\n?|\n").ToList();
        }

        private DateTime getDateTime(string text)
        {
            if(text == "" || text == "01/01/0001 0:00:00")
            {
                return new DateTime();
            }
            else
            {
                try
                {
                    return DateTime.ParseExact(text, "dd/MM/yyyy H:mm", CultureInfo.InvariantCulture);
                }
                catch
                {
                    try
                    {
                        return DateTime.ParseExact(text, "dd/MM/yyyy H:mm:ss", CultureInfo.InvariantCulture);
                    }
                    catch
                    {
                        return new DateTime();
                    }
                }
            }
        }
    }


    // DO NOT USE. CsvHelper sucks at handling conversions properly.
    public sealed class TestcaseMap : ClassMap<Testcase>
    {
        public TestcaseMap()
        {
            Map(m => m.PatientID).Index(0);
            // Notes Link (not used)    1
            // Hypokalemia Data Link (not used) 2
            // All Data Link (not used) 2
            Map(m => m.Potassium1).Index(4);
            Map(m => m.K1Date).Index(5).ConvertUsing(row => DateTime.ParseExact(row.GetField(5), "dd/MM/yyyy H:mm", CultureInfo.InvariantCulture));
            Map(m => m.Potassium2).Index(6);
            Map(m => m.K2Date).Index(7).ConvertUsing(row => DateTime.ParseExact(row.GetField(7), "dd/MM/yyyy H:mm", CultureInfo.InvariantCulture));
            // K 2 hours (not used)     8
            Map(m => m.Potassium3).Index(9);
            Map(m => m.K3Date).Index(10).ConvertUsing(row => DateTime.ParseExact(row.GetField(10), "dd/MM/yyyy H:mm", CultureInfo.InvariantCulture));
            // K 3 hours (not used)     11
            Map(m => m.Dialysis).Index(12);
            Map(m => m.Gender).Index(13);
            Map(m => m.Ethnicity).Index(14);
            Map(m => m.DOB).Index(15);
            // Age (not used)           16
            Map(m => m.Creatinine1).Index(17);
            Map(m => m.SCr1date).Index(18).ConvertUsing(row => DateTime.ParseExact(row.GetField(18), "dd/MM/yyyy H:mm", CultureInfo.InvariantCulture));
            // SCr 1 hours (not used)   19
            Map(m => m.Creatinine2).Index(20);
            Map(m => m.SCr2date).Index(21).ConvertUsing(row => DateTime.ParseExact(row.GetField(21), "dd/MM/yyyy H:mm", CultureInfo.InvariantCulture));
            // SCr 2 hours (not used)   22
            Map(m => m.Creatinine3).Index(23);
            Map(m => m.SCr3date).Index(24).ConvertUsing(row => DateTime.ParseExact(row.GetField(24), "dd/MM/yyyy H:mm", CultureInfo.InvariantCulture));
            // SCr 3 hours (not used)   25
            Map(m => m.CCR1).Index(26);
            Map(m => m.CCR1date).Index(27).ConvertUsing(row => DateTime.ParseExact(row.GetField(27), "dd/MM/yyyy H:mm", CultureInfo.InvariantCulture));
            // CCR 1 hours (not used)   28
            Map(m => m.CCR2).Index(29);
            Map(m => m.CCR2date).Index(30).ConvertUsing(row => DateTime.ParseExact(row.GetField(30), "dd/MM/yyyy H:mm", CultureInfo.InvariantCulture));
            // CCR 2 hours (not used)   31
            Map(m => m.CCR3).Index(32);
            Map(m => m.CCR3date).Index(33).ConvertUsing(row => DateTime.ParseExact(row.GetField(33), "dd/MM/yyyy H:mm", CultureInfo.InvariantCulture));
            // CCR 3 hours (not used)   34
            Map(m => m.UrineProduction3hours).Index(35);
            Map(m => m.UrineProduction6hours).Index(36);
            Map(m => m.UrineProduction24hours).Index(37);
            Map(m => m.Weight).Index(38);
            Map(m => m.WtDate).Index(39).ConvertUsing(row => DateTime.ParseExact(row.GetField(39), "dd/MM/yyyy H:mm", CultureInfo.InvariantCulture));
            // Wt hours (not used)      40
            Map(m => m.LoopDiureticsDsc).Index(41);
            Map(m => m.Diarrhea).Index(42);
            Map(m => m.Supplement24hrs).Index(43);
            Map(m => m.Supplement48hrs).Index(44);
            Map(m => m.Phosphorus).Index(45);
            Map(m => m.PhosDate).Index(46).ConvertUsing(row => DateTime.ParseExact(row.GetField(46), "dd/MM/yyyy H:mm", CultureInfo.InvariantCulture));
            // Phosphate hours (not used)   47
            Map(m => m.Calcium).Index(48);
            Map(m => m.CaDate).Index(49).ConvertUsing(row => DateTime.ParseExact(row.GetField(49), "dd/MM/yyyy H:mm", CultureInfo.InvariantCulture));
            // Ca hours (not used)          50
            Map(m => m.CaType).Index(51);
            Map(m => m.Albumin).Index(52);
            Map(m => m.AlbDate).Index(53).ConvertUsing(row => DateTime.ParseExact(row.GetField(53), "dd/MM/yyyy H:mm", CultureInfo.InvariantCulture));
            // Albumin hours (not used)     54
            Map(m => m.Magnesium).Index(55);
            Map(m => m.MgDate).Index(56).ConvertUsing(row => DateTime.ParseExact(row.GetField(56), "dd/MM/yyyy H:mm", CultureInfo.InvariantCulture));
            // Mg hours (not used)          57
            // Not used, spacer             58
            Map(m => m.Supplements).Index(59); // takes all the rest of the line
            // Not used, spacer             60
            Map(m => m.Treatments).Index(61);
            Map(m => m.Actions).Index(62);
            Map(m => m.Reasons).Index(63);
        }
    }
}