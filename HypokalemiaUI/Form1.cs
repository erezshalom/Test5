using System;
using System.Collections.Generic;
using System.Drawing;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Windows.Forms;

using AutoICU.AI;
using AutoICU.AI.HypokalemiaV1;

namespace HyperkalemiaUI
{
    public partial class TopForm : Form
    {
        private class ValueSet
        {
            public string Value { get; set; }
            public string DT1 { get; set; }
            public string DT2 { get; set; }
            public string DT3 { get; set; }
            public string DT4 { get; set; }
            public string DT5 { get; set; }

            public ValueSet(string name)
            {
                this.Value = name;
                DT1 = "";
                DT2 = "";
                DT3 = "";
                DT4 = "";
                DT5 = "";
            }
        }

        public TopForm()
        {
            InitializeComponent();
            List<ValueSet> values = new List<ValueSet>();
            values.Add(new ValueSet("Date"));
            values.Add(new ValueSet("Time"));
            values.Add(new ValueSet("GFR (ml/min)"));
            values.Add(new ValueSet("Urine Production (ml/kg/hr)"));
            values.Add(new ValueSet("Potassium (mEq/l)"));
            values.Add(new ValueSet("Magnesium (mg/dl)"));
            values.Add(new ValueSet("Phosphorus (mg/dl)"));
            values.Add(new ValueSet("Calcium, Ionized (mg/dl)"));
            values.Add(new ValueSet("Diarrhea (Y/N)"));
            valuesDataGridView.DataSource = values;
            valuesDataGridView.ClearSelection();

            List<ValueSet> treatments = new List<ValueSet>();
            treatments.Add(new ValueSet("Date"));
            treatments.Add(new ValueSet("Time"));
            treatments.Add(new ValueSet("KCL (mEq)"));
            //treatments.Add(new ValueSet("K-Phos (mg Phos)"));
            //treatments.Add(new ValueSet("MgSO4 (g)"));
            //treatments.Add(new ValueSet("Ca Glu (mg/dl)"));
            medsDataGridView.DataSource = treatments;
            medsDataGridView.ClearSelection();
        }

        private void RunButton_Click(object sender, EventArgs e)
        {
            CultureInfo culture = new CultureInfo("en-US");

            List<AutoICU.AI.Treatment> treatments = new List<AutoICU.AI.Treatment>();
            List<AutoICU.AI.Action> actions = new List<AutoICU.AI.Action>();
            List<AutoICU.AI.Reason> reasons = new List<AutoICU.AI.Reason>();

            List<double> test_x_values = new List<double>();
            List<double> test_y_values = new List<double>();
            List<double> treatment_x_values = new List<double>();
            List<double> treatment_y_values = new List<double>();
            List<double> weights = new List<double>();
            DateTime now = DateTime.Now;

            AutoICU.AI.ValueTable testData = new ValueTable();
            bool latestSet = false;
            DateTime latest = DateTime.UtcNow;
            for(int dt_index = 1; dt_index < valuesDataGridView.ColumnCount; dt_index++)
            {
                string date = valuesDataGridView.Rows[0].Cells[dt_index].Value.ToString();
                string time = valuesDataGridView.Rows[1].Cells[dt_index].Value.ToString();

                if (date != "")
                {
                    if (time == "")
                    {
                        time = "12:00";
                    }
                    else
                    {
                        if (!time.Contains(":") && time.Length > 2)
                        {
                            time = time.Substring(0, time.Length - 2) + ":" + time.Substring(time.Length - 2);
                        }
                    }
                    try
                    {
                        DateTime timestamp = Convert.ToDateTime(date + " " + time, culture);
                        if(!latestSet)
                        {
                            latest = timestamp;
                            latestSet = true;
                        }
                        for (int test_index = 2; test_index < valuesDataGridView.RowCount; test_index++)
                        {
                            string testName = valuesDataGridView.Rows[test_index].Cells[0].Value.ToString();
                            string testValue = valuesDataGridView.Rows[test_index].Cells[dt_index].Value as string;
                            if (testValue != "")
                            {
                                testData.SetValue(testName, testValue, "", timestamp);
                            }
                        }
                    }
                    catch (Exception)
                    {
                        AutoICU.AI.Action action = new AutoICU.AI.Action();
                        action.text = "Unusable date and/or time: " + date + " " + time;
                        actions.Add(action);
                    }
                }
            }

            if(enteralRouteCheckBox.Checked)
            {
                testData.SetValue("EnteralRoute", true, "", latest);
            }
            if (centralIvRouteCheckBox.Checked)
            {
                testData.SetValue("CentralRoute", true, "", latest);
            }
            if (peripheralIvRouteCheckBox.Checked)
            {
                testData.SetValue("PeripheralRoute", true, "", latest);
            }

            AutoICU.AI.ValueTable treatmentData = new ValueTable();
            for (int dt_index = 1; dt_index < medsDataGridView.ColumnCount; dt_index++)
            {
                string date = medsDataGridView.Rows[0].Cells[dt_index].Value.ToString();
                string time = medsDataGridView.Rows[1].Cells[dt_index].Value.ToString();

                if (date != "")
                {
                    if (time == "")
                    {
                        time = "12:00";
                    }
                    else
                    {
                        if (!time.Contains(":") && time.Length > 2)
                        {
                            time = time.Substring(0, time.Length - 2) + ":" + time.Substring(time.Length - 2);
                        }
                    }
                    try
                    {
                        DateTime timestamp = Convert.ToDateTime(date + " " + time, culture);
                        for (int test_index = 2; test_index < medsDataGridView.RowCount; test_index++)
                        {
                            string treatmentName = medsDataGridView.Rows[test_index].Cells[0].Value.ToString();
                            string treatmentValue = medsDataGridView.Rows[test_index].Cells[dt_index].Value as string;
                            if (treatmentValue != "")
                            {
                                treatmentData.SetValue(treatmentName, treatmentValue, "", timestamp);
                            }
                        }
                    }
                    catch (Exception)
                    {
                        AutoICU.AI.Action action = new AutoICU.AI.Action();
                        action.text = "Unusable date and/or time: " + date + " " + time;
                        actions.Add(action);
                    }
                }
            }

            AutoICU.AI.Intervention hypokalemia = new AutoICU.AI.HypokalemiaV1.Module("p123456", testData, treatmentData);
            DecisionResult results = hypokalemia.IdentifyTreatment();

            treatementsDataGridView.DataSource = results.treatments;
            treatementsDataGridView.ClearSelection();

            actionsDataGridView.DataSource = results.actions;
            actionsDataGridView.ClearSelection();

            reasonsDataGridView.DataSource = results.reasons;
            reasonsDataGridView.ClearSelection();

            // Tests the loading of AutoICU.AI intervention modules and running them.
            //Physician.LoadAssemblies();
            //Physician.IdentifyTreatments("p123456", testData, treatmentData);
        }

        DateTimePicker dtp = null;
        DataGridView currentTable = null;
        int columnIndex = 0;
        int rowIndex = 0;
        private void valuesDataGridView_CellClick(object sender, DataGridViewCellEventArgs e)
        {
            currentTable = valuesDataGridView;
            selectDate(sender, e);
        }

        private void medsDataGridView_CellClick(object sender, DataGridViewCellEventArgs e)
        {
            currentTable = medsDataGridView;
            selectDate(sender, e);
        }

        private void selectDate(object sender, DataGridViewCellEventArgs e)
        { 
            if (e.RowIndex == 0 && e.ColumnIndex > 0)
            {
                rowIndex = e.RowIndex;
                columnIndex = e.ColumnIndex;
                dtp = new DateTimePicker();
                currentTable.Controls.Add(dtp);
                dtp.Format = DateTimePickerFormat.Custom;
                dtp.CustomFormat = "MM-dd-yyyy";
                Rectangle rectangle = currentTable.GetCellDisplayRectangle(e.ColumnIndex, e.RowIndex, true);
                dtp.Size = new Size(rectangle.Width, rectangle.Height);
                dtp.Location = new Point(rectangle.X, rectangle.Y);

                dtp.CloseUp += new EventHandler(dtp_CloseUp);
                dtp.TextChanged += new EventHandler(dtp_OnTextChange);


                dtp.Visible = true;
            }
        }
        private void dtp_OnTextChange(object sender, EventArgs e)
        {
            currentTable.CurrentCell.Value = dtp.Text.ToString();
        }
        void dtp_CloseUp(object sender, EventArgs e)
        {
            dtp.Visible = false;
        }
        void valuesDataGridView_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyCode == Keys.Delete)
            {
                valuesDataGridView.CurrentCell.Value = "";
                if (dtp != null)
                {
                    dtp.Visible = false;
                }
            }
        }
        void medsDataGridView_KeyUp(object sender, KeyEventArgs e)
        {
            if (e.KeyCode == Keys.Delete)
            {
                medsDataGridView.CurrentCell.Value = "";
                if (dtp != null)
                {
                    dtp.Visible = false;
                }
            }
        }

        private SaveFileDialog saveFileDialog = new SaveFileDialog();
        private void SaveButton_Click(object sender, EventArgs e)
        {
            saveFileDialog.ShowDialog();
            if (saveFileDialog.FileName != "")
            {
                System.IO.FileStream fs = (System.IO.FileStream)saveFileDialog.OpenFile();
                using (StreamWriter file = new StreamWriter(fs))
                {
                    for (int x = 1; x < valuesDataGridView.ColumnCount; x++)
                    {
                        for (int y = 0; y < valuesDataGridView.RowCount; y++)
                        {
                            string value = valuesDataGridView[x, y].Value.ToString();
                            if (value != "")
                            {
                                file.WriteLine(x + "\t" + y + "\t" + valuesDataGridView[0, y].Value + "\t" + value);
                            }
                        }
                    }
                    file.WriteLine("Treatments");
                    for (int x = 1; x < medsDataGridView.ColumnCount; x++)
                    {
                        for (int y = 0; y < medsDataGridView.RowCount; y++)
                        {
                            string value = medsDataGridView[x, y].Value.ToString();
                            if (value != "")
                            {
                                file.WriteLine(x + "\t" + y + "\t" + medsDataGridView[0, y].Value + "\t" + value);
                            }
                        }
                    }
                }
                fs.Close();
            }
        }

        private OpenFileDialog openFileDialog = new OpenFileDialog();
        private void LoadButton_Click(object sender, EventArgs e)
        {
            openFileDialog.InitialDirectory = Directory.GetCurrentDirectory();
            openFileDialog.Filter = "Data files (*.txt)|*.txt|All files (*.*)|*.*";
            openFileDialog.ShowDialog();
            if(openFileDialog.FileName != "")
            {
                System.IO.FileStream fs = (System.IO.FileStream)openFileDialog.OpenFile();
                using (StreamReader file = new StreamReader(fs))
                {
                    for (int x = 1; x < valuesDataGridView.ColumnCount; x++)
                    {
                        for (int y = 0; y < valuesDataGridView.RowCount; y++)
                        {
                            valuesDataGridView[x, y].Value = "";
                        }
                    }
                    for (int x = 1; x < medsDataGridView.ColumnCount; x++)
                    {
                        for (int y = 0; y < medsDataGridView.RowCount; y++)
                        {
                            medsDataGridView[x, y].Value = "";
                        }
                    }
                    string line;
                    DataGridView view = valuesDataGridView;
                    while ((line = file.ReadLine()) != null)
                    {
                        if (line.ToLower() == "treatments")
                        {
                            view = medsDataGridView;
                        }
                        else
                        {
                            string[] parts = line.Split(new char[] { '\t' });
                            if (parts.Length == 4)
                            {
                                int x;
                                int y;
                                string name;
                                string value;
                                if (int.TryParse(parts[0], out x) && int.TryParse(parts[1], out y))
                                {
                                    name = parts[2];
                                    value = parts[3];
                                    view[x, y].Value = value;
                                }
                            }
                        }
                    }
                }
                fs.Close();
            }
        }
    }
}

