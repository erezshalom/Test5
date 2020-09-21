using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TestUI
{
    public class Testcase
    {
        public string ID = "";          // MIMIC III hadm_id
        public string gender = "";      // GFR input
        public string DOB = "";         // GFR input (as age)
        public string ethnicity = "";   // GFR input
        public string intervention = "Hypokalemia";
        public List<GenericEvent> events = new List<GenericEvent>();

        public static Testcase Read(string patientID)
        {
            Testcase testCase = new Testcase();
            // Read subject.csv to get the patient data
            // Read icustay.csv to get the stays
            // Read the events files to get the events
            return testCase;
        }

        public int age(DateTime timestamp)
        {
            int age = -1;
            DateTime dobTimestamp;
            if (DateTime.TryParse(DOB, out dobTimestamp))
            {
                age = timestamp.Year - dobTimestamp.Year;
                if(dobTimestamp.AddYears(age) > timestamp) 
                {
                    age--; // Before this year's birthday
                }
            }
            return age;
        }

        // Functions to get the requested value
        // Requires that events are sorted by ascending chartDateTime.
        public GenericEvent GetLatestEvent(string[] names, DateTime timestamp)
        {
            GenericEvent result = null;
            foreach(GenericEvent genericEvent in events)
            {
                if(genericEvent.chartDateTime >= timestamp)
                {
                    break;
                }
                if(names.Contains(genericEvent.label))
                {
                    result = genericEvent;
                }
            }
            return result;
        }

        // Functions to get the requested value
        // Requires that events are sorted by ascending chartDateTime.
        public GenericEvent GetLatestLabEvent(string[] names, DateTime timestamp)
        {
            GenericEvent result = null;
            foreach (GenericEvent genericEvent in events)
            {
                if (genericEvent.chartDateTime >= timestamp)
                {
                    break;
                }
                if (genericEvent.type == "labevent" && names.Contains(genericEvent.label))
                {
                    result = genericEvent;
                }
            }
            return result;
        }

        // Functions to get the requested value
        // Requires that events are sorted by ascending chartDateTime.
        public GenericEvent GetLatestOutputEvent(string[] names, DateTime timestamp)
        {
            GenericEvent result = null;
            foreach (GenericEvent genericEvent in events)
            {
                if (genericEvent.chartDateTime >= timestamp)
                {
                    break;
                }
                if (genericEvent.type == "labevent" && names.Contains(genericEvent.label))
                {
                    result = genericEvent;
                }
            }
            return result;
        }

        // Functions to get the requested value
        // Requires that events are sorted by ascending chartDateTime.
        public List<GenericEvent> GetLatestPrescriptionEvents(string[] names, DateTime startTimestamp, DateTime endTimeStamp)
        {
            List<GenericEvent> results = new List<GenericEvent>();
            foreach (GenericEvent genericEvent in events)
            {
                if (genericEvent.chartDateTime >= endTimeStamp)
                {
                    break;
                }
                if (genericEvent.chartDateTime >= startTimestamp && genericEvent.type == "prescription" && names.Contains(genericEvent.label))
                {
                    results.Add(genericEvent);
                }
            }
            return results;
        }
    }

    public class GenericEvent // Covers all types of events
    {
        public string type = "";
        public string label = "";       // chartevent, inputevents_cv, labevents, outputevents, prescriptions drug
        public string chartTime = "";   // chartevent, inputevents_cv, labevents, outputevents, prescriptions startdate
        public string endTime = "";     // prescriptions enddate
        public string value = "";       // chartevent, inputevents_cv amount, labevents, outputevents
        public double valueNum = 0.0;   // chartevent valuenum, inputevents_cv amount, labevents valuenum, outputevents value, prescriptions dose_val_rx
        public string valueUnits = "";  // chartevent valueuom, inputevents_cv amountuom, labevents valueuom, outputevents valueuom, prescriptions dose_unit_rx
        public string rate = "";        // inputevents_cv rate or originalrate, prescriptions form_val_disp
        public string rateUnits = "";   // inputevents_cv rateuom or originalrateuom, prescriptions form_unit_disp
        public string route = "";       // inputevents_cv originalroute, prescriptions route
        public DateTime chartDateTime;  // chartevent, inputevents_cv, prescriptions startdate
        public DateTime endDateTime;    // prescriptions enddate
        public string flag = "";        // labevents
        public string fluid = "";       // labevents
        public string category = "";    // labevents; prescriptions drug_type
        public string drugNamePOE = ""; // prescriptions drug_name_poe
        public string drugNameGeneric = ""; // prescriptions drug_name_generic
        public string strength = "";    // prescriptions drug_type
    }
}
