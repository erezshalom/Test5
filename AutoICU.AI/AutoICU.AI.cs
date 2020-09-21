using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Globalization;
using System.Reflection;

namespace AutoICU.AI
{
    public class General
    {
        public static CultureInfo GetCulture()
        {
            return new CultureInfo("en-US");
        }
    }

    // Physician loads all available intervention modules and runs them on supplied data.
    public class Physician
    {
        private static List<Assembly> assemblies = new List<Assembly>();
        public static void LoadAssemblies()
        {
            foreach(string fileName in Directory.EnumerateFiles(".", "*.dll"))
            {
                if (fileName.StartsWith(".\\AutoICU.AI.") && fileName != ".\\AutoICU.AI.dll")
                {
                    Assembly assembly = Assembly.LoadFrom(fileName);
                    assemblies.Add(assembly);
                }
            }
        }

        public static List<DecisionResult> IdentifyTreatments(string patient, ValueTable testData, ValueTable treatmentData)
        {
            List<DecisionResult> results = new List<DecisionResult>();
            foreach(Assembly assem in assemblies)
            {
                Intervention intervention = (Intervention) assem.CreateInstance(assem.GetName().Name + ".Module",
                    false, 0, null, new object[] { patient, testData, treatmentData}, null, null);
                if(intervention != null && intervention.Diagnose())
                {
                    results.Add(intervention.IdentifyTreatment());
                }
            }
            return results;
        }
    }

    public abstract class Intervention
    {
        protected string patientID;
        protected ValueTable testData;
        protected ValueTable treatmentData;

        public Intervention(string patientID, ValueTable testData, ValueTable treatmentData)
        {
            this.patientID = patientID;
            this.testData = testData;
            this.treatmentData = treatmentData;
        }

        // True if the patient requires treatment of the intervention.
        public abstract bool Diagnose();
        public abstract DecisionResult IdentifyTreatment();
        public abstract List<string> DataValues();
    }

    // The Value class implements a single value. This value may be numeric or symbolic.
    // Values are organized into a ValueTable which allows access by value name or timestamp.
        public class Value
    {
        public string name;
        public object value;
        public string units;
        public double offset;
        public DateTime timestamp;

        public Value(string name, object value, string units, DateTime timestamp)
        {
            // Remove units if any
            if(name.IndexOf('(') > -1)
            {
                this.name = name.Substring(0, name.IndexOf('(') - 1).ToLower();
            }
            else
            {
                this.name = name.ToLower();
            }
            // Handle string to double conversion
            double doubleValue = 0.0;
            if(value is string && double.TryParse(value as string, out doubleValue))
            {
                this.value = doubleValue;
            }
            else
            {
                this.value = value;
            }
            this.units = units;
            this.timestamp = timestamp;
            offset = -1;
        }

        public override string ToString()
        {
            return value.ToString();
        }
    }

    public class ValueTable
    {
        private Dictionary<string, Dictionary<double, Value>> dataByName = new Dictionary<string, Dictionary<double, Value>>();
        private Dictionary<double, Dictionary<string, Value>> dataByTimestamp = new Dictionary<double, Dictionary<string, Value>>();
        private DateTime now = DateTime.UtcNow;

        public ValueTable()
        {
        }

        public ValueTable(DateTime referenceTimestamp)
        {
            now = referenceTimestamp;
        }

        public int NameCount()
        {
            return dataByName.Keys.Count;
        }

        public int OffsetCount()
        {
            return dataByTimestamp.Keys.Count;
        }

        public ValueTable SetValue(string name, object value, string units, DateTime timestamp)
        {
            return SetValue(new Value(name, value, units, timestamp));
        }

        public ValueTable SetValue(Value newValue)
        {
            string name = newValue.name;
            newValue.offset = (now - newValue.timestamp).TotalSeconds;

            Dictionary<double, Value> nameValues = null;
            if(dataByName.TryGetValue(name, out nameValues))
            {
                dataByName[name][newValue.offset] = newValue;
            }
            else
            {
                dataByName[name] = new Dictionary<double, Value>() { { newValue.offset, newValue } };
            }

            Dictionary<string, Value> timestampValues = null;
            if (dataByTimestamp.TryGetValue(newValue.offset, out timestampValues))
            {
                timestampValues[name] = newValue;
            }
            else
            {
                dataByTimestamp[newValue.offset] = new Dictionary<string, Value>() { { name, newValue } };
            }

            return this;
        }

        // Return the values in order of ascending offsets (most recent first)
        public List<Value> Values(string name)
        {
            Dictionary<double, Value> nameValues = null;
            if (dataByName.TryGetValue(name, out nameValues))
            {
                return nameValues.Values.OrderBy(v => v.offset).ToList();
            }
            else
            {
                return new List<Value>();
            }
        }

        public List<Value> Values(double offset)
        {
            Dictionary<string, Value> timestampValues = null;
            if (dataByTimestamp.TryGetValue(offset, out timestampValues))
            {
                return timestampValues.Values.ToList();
            }
            else
            {
                return new List<Value>();
            }
        }

        public List<Value> Values(DateTime timestamp)
        {
            return Values((now - timestamp).TotalSeconds);
        }

        public List<Value> Values()
        {
            List<Value> values = new List<Value>();
            foreach(string name in Names())
            {
                values.AddRange(Values(name));
            }
            return values;
        }

        public Value Value(string name, double offset)
        {
            Dictionary<double, Value> nameValues = null;
            if (dataByName.TryGetValue(name, out nameValues))
            {
                Value value = null;
                if (nameValues.TryGetValue(offset, out value))
                {
                    return value;
                }
                else
                {
                    if (nameValues.Count > 0) // Get the latest
                    {
                        return nameValues.OrderByDescending(nv => nv.Key).ToList()[0].Value;
                    }
                    else
                    {
                        return new Value("", null, "", DateTime.UtcNow);
                    }
                }
            }
            else
            {
                return new Value("", null, "", DateTime.UtcNow);
            }
        }

        public Value Value(string name, DateTime timestamp)
        {
            return Value(name, (now - timestamp).TotalSeconds);
        }

        public List<string> Names()
        {
            return dataByName.Keys.ToList();
        }

        public List<double> Offsets()
        {
            return dataByTimestamp.Keys.ToList();
        }
    }

    public class DecisionResult
    {
        public DecisionResult()
        {

        }

        public DecisionResult(List<Treatment> treatments, List<Action> actions, List<Reason> reasons)
        {
            this.treatments = treatments;
            this.actions = actions;
            this.reasons = reasons;
        }

        public List<Treatment> treatments;
        public List<Action> actions;
        public List<Reason> reasons;
    }

    //(deftemplate treatment
    //    (slot index); Used to group the treatments which must be given together
    //    (slot type); RECOMMENDED or ALTERNATE
    //    (slot med); Name of the med or treatment
    //    (slot quantity); Numeric value
    //    (slot units); Units of the quantity
    //    (slot route))	; ENTERAL or CENTRAL-IV or PERIPHERAL-IV
    public class Treatment
    {
        public float index { get; set; }
        public string type { get; set; }
        public string med { get; set; }
        public double quantity { get; set; }
        public string units { get; set; }
        public string route { get; set; }
    }

    //(deftemplate action
    //    (slot text))
    public class Action
    {
        public string text { get; set; }

        public Action(string text = "")
        {
            this.text = text;
        }
    }

    //(deftemplate reason
    //    (slot level)
    //    (slot rule)
    //    (slot reason))
    public class Reason
    {
        public int level { get; set; }
        public string rule { get; set; }
        public string text { get; set; }

        public Reason(int level, string rule, string text)
        {
            this.level = level;
            this.rule = rule;
            this.text = text;
        }
    }
}
