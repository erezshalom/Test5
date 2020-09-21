namespace HyperkalemiaUI
{
    partial class TopForm
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.InputDataGroup = new System.Windows.Forms.GroupBox();
            this.label2 = new System.Windows.Forms.Label();
            this.medsDataGridView = new System.Windows.Forms.DataGridView();
            this.SaveButton = new System.Windows.Forms.Button();
            this.LoadButton = new System.Windows.Forms.Button();
            this.label1 = new System.Windows.Forms.Label();
            this.valuesDataGridView = new System.Windows.Forms.DataGridView();
            this.Value = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.DT1 = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.DT2 = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.DT3 = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.DT4 = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.DT5 = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.peripheralIvRouteCheckBox = new System.Windows.Forms.CheckBox();
            this.centralIvRouteCheckBox = new System.Windows.Forms.CheckBox();
            this.enteralRouteCheckBox = new System.Windows.Forms.CheckBox();
            this.label6 = new System.Windows.Forms.Label();
            this.RunButton = new System.Windows.Forms.Button();
            this.TreatmentGroup = new System.Windows.Forms.GroupBox();
            this.treatementsDataGridView = new System.Windows.Forms.DataGridView();
            this.TreatmentIndex = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.TreatmentType = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.TreatmentMed = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.TreatmentQuantity = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.TreatmentUnits = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.TreatmentRoute = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.ReasoningGroup = new System.Windows.Forms.GroupBox();
            this.reasonsDataGridView = new System.Windows.Forms.DataGridView();
            this.ReasonLevel = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.ReasonReason = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.Rule = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.ActionsGroup = new System.Windows.Forms.GroupBox();
            this.actionsDataGridView = new System.Windows.Forms.DataGridView();
            this.ActionText = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.dataGridViewTextBoxColumn1 = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.dataGridViewTextBoxColumn2 = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.dataGridViewTextBoxColumn3 = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.dataGridViewTextBoxColumn4 = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.dataGridViewTextBoxColumn5 = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.dataGridViewTextBoxColumn6 = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.InputDataGroup.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.medsDataGridView)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.valuesDataGridView)).BeginInit();
            this.TreatmentGroup.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.treatementsDataGridView)).BeginInit();
            this.ReasoningGroup.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.reasonsDataGridView)).BeginInit();
            this.ActionsGroup.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.actionsDataGridView)).BeginInit();
            this.SuspendLayout();
            // 
            // InputDataGroup
            // 
            this.InputDataGroup.Controls.Add(this.label2);
            this.InputDataGroup.Controls.Add(this.medsDataGridView);
            this.InputDataGroup.Controls.Add(this.SaveButton);
            this.InputDataGroup.Controls.Add(this.LoadButton);
            this.InputDataGroup.Controls.Add(this.label1);
            this.InputDataGroup.Controls.Add(this.valuesDataGridView);
            this.InputDataGroup.Controls.Add(this.peripheralIvRouteCheckBox);
            this.InputDataGroup.Controls.Add(this.centralIvRouteCheckBox);
            this.InputDataGroup.Controls.Add(this.enteralRouteCheckBox);
            this.InputDataGroup.Controls.Add(this.label6);
            this.InputDataGroup.Controls.Add(this.RunButton);
            this.InputDataGroup.Location = new System.Drawing.Point(19, 2);
            this.InputDataGroup.Name = "InputDataGroup";
            this.InputDataGroup.Size = new System.Drawing.Size(592, 462);
            this.InputDataGroup.TabIndex = 0;
            this.InputDataGroup.TabStop = false;
            this.InputDataGroup.Text = "Input Data";
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Location = new System.Drawing.Point(13, 271);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(91, 13);
            this.label2.TabIndex = 23;
            this.label2.Text = "Treatments Given";
            // 
            // medsDataGridView
            // 
            this.medsDataGridView.AllowUserToAddRows = false;
            this.medsDataGridView.AllowUserToDeleteRows = false;
            this.medsDataGridView.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            this.medsDataGridView.ColumnHeadersVisible = false;
            this.medsDataGridView.Columns.AddRange(new System.Windows.Forms.DataGridViewColumn[] {
            this.dataGridViewTextBoxColumn1,
            this.dataGridViewTextBoxColumn2,
            this.dataGridViewTextBoxColumn3,
            this.dataGridViewTextBoxColumn4,
            this.dataGridViewTextBoxColumn5,
            this.dataGridViewTextBoxColumn6});
            this.medsDataGridView.Location = new System.Drawing.Point(6, 287);
            this.medsDataGridView.Name = "medsDataGridView";
            this.medsDataGridView.RowHeadersVisible = false;
            this.medsDataGridView.Size = new System.Drawing.Size(576, 72);
            this.medsDataGridView.TabIndex = 22;
            this.medsDataGridView.CellClick += new System.Windows.Forms.DataGridViewCellEventHandler(this.medsDataGridView_CellClick);
            this.medsDataGridView.KeyUp += new System.Windows.Forms.KeyEventHandler(this.medsDataGridView_KeyUp);
            // 
            // SaveButton
            // 
            this.SaveButton.Location = new System.Drawing.Point(151, 432);
            this.SaveButton.Name = "SaveButton";
            this.SaveButton.Size = new System.Drawing.Size(75, 23);
            this.SaveButton.TabIndex = 21;
            this.SaveButton.Text = "Save";
            this.SaveButton.UseVisualStyleBackColor = true;
            this.SaveButton.Click += new System.EventHandler(this.SaveButton_Click);
            // 
            // LoadButton
            // 
            this.LoadButton.Location = new System.Drawing.Point(26, 432);
            this.LoadButton.Name = "LoadButton";
            this.LoadButton.Size = new System.Drawing.Size(75, 23);
            this.LoadButton.TabIndex = 20;
            this.LoadButton.Text = "Load";
            this.LoadButton.UseVisualStyleBackColor = true;
            this.LoadButton.Click += new System.EventHandler(this.LoadButton_Click);
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(6, 245);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(160, 13);
            this.label1.TabIndex = 19;
            this.label1.Text = "Enter -1 for GFR if under Dialysis";
            // 
            // valuesDataGridView
            // 
            this.valuesDataGridView.AllowUserToAddRows = false;
            this.valuesDataGridView.AllowUserToDeleteRows = false;
            this.valuesDataGridView.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            this.valuesDataGridView.ColumnHeadersVisible = false;
            this.valuesDataGridView.Columns.AddRange(new System.Windows.Forms.DataGridViewColumn[] {
            this.Value,
            this.DT1,
            this.DT2,
            this.DT3,
            this.DT4,
            this.DT5});
            this.valuesDataGridView.Location = new System.Drawing.Point(9, 37);
            this.valuesDataGridView.Name = "valuesDataGridView";
            this.valuesDataGridView.RowHeadersVisible = false;
            this.valuesDataGridView.Size = new System.Drawing.Size(576, 205);
            this.valuesDataGridView.TabIndex = 18;
            this.valuesDataGridView.CellClick += new System.Windows.Forms.DataGridViewCellEventHandler(this.valuesDataGridView_CellClick);
            this.valuesDataGridView.KeyUp += new System.Windows.Forms.KeyEventHandler(this.valuesDataGridView_KeyUp);
            // 
            // Value
            // 
            this.Value.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.AllCellsExceptHeader;
            this.Value.DataPropertyName = "Value";
            this.Value.HeaderText = "Value";
            this.Value.Name = "Value";
            this.Value.Width = 5;
            // 
            // DT1
            // 
            this.DT1.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.Fill;
            this.DT1.DataPropertyName = "DT1";
            this.DT1.HeaderText = "DT1";
            this.DT1.Name = "DT1";
            // 
            // DT2
            // 
            this.DT2.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.Fill;
            this.DT2.DataPropertyName = "DT2";
            this.DT2.HeaderText = "DT2";
            this.DT2.Name = "DT2";
            // 
            // DT3
            // 
            this.DT3.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.Fill;
            this.DT3.DataPropertyName = "DT3";
            this.DT3.HeaderText = "DT3";
            this.DT3.Name = "DT3";
            // 
            // DT4
            // 
            this.DT4.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.Fill;
            this.DT4.DataPropertyName = "DT4";
            this.DT4.HeaderText = "DT4";
            this.DT4.Name = "DT4";
            // 
            // DT5
            // 
            this.DT5.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.Fill;
            this.DT5.DataPropertyName = "DT5";
            this.DT5.HeaderText = "DT5";
            this.DT5.Name = "DT5";
            // 
            // peripheralIvRouteCheckBox
            // 
            this.peripheralIvRouteCheckBox.AutoSize = true;
            this.peripheralIvRouteCheckBox.Checked = true;
            this.peripheralIvRouteCheckBox.CheckState = System.Windows.Forms.CheckState.Checked;
            this.peripheralIvRouteCheckBox.Location = new System.Drawing.Point(265, 19);
            this.peripheralIvRouteCheckBox.Name = "peripheralIvRouteCheckBox";
            this.peripheralIvRouteCheckBox.Size = new System.Drawing.Size(86, 17);
            this.peripheralIvRouteCheckBox.TabIndex = 16;
            this.peripheralIvRouteCheckBox.Text = "Peripheral IV";
            this.peripheralIvRouteCheckBox.UseVisualStyleBackColor = true;
            // 
            // centralIvRouteCheckBox
            // 
            this.centralIvRouteCheckBox.AutoSize = true;
            this.centralIvRouteCheckBox.Checked = true;
            this.centralIvRouteCheckBox.CheckState = System.Windows.Forms.CheckState.Checked;
            this.centralIvRouteCheckBox.Location = new System.Drawing.Point(187, 19);
            this.centralIvRouteCheckBox.Name = "centralIvRouteCheckBox";
            this.centralIvRouteCheckBox.Size = new System.Drawing.Size(72, 17);
            this.centralIvRouteCheckBox.TabIndex = 15;
            this.centralIvRouteCheckBox.Text = "Central IV";
            this.centralIvRouteCheckBox.UseVisualStyleBackColor = true;
            // 
            // enteralRouteCheckBox
            // 
            this.enteralRouteCheckBox.AutoSize = true;
            this.enteralRouteCheckBox.Checked = true;
            this.enteralRouteCheckBox.CheckState = System.Windows.Forms.CheckState.Checked;
            this.enteralRouteCheckBox.Location = new System.Drawing.Point(112, 19);
            this.enteralRouteCheckBox.Name = "enteralRouteCheckBox";
            this.enteralRouteCheckBox.Size = new System.Drawing.Size(59, 17);
            this.enteralRouteCheckBox.TabIndex = 14;
            this.enteralRouteCheckBox.Text = "Enteral";
            this.enteralRouteCheckBox.UseVisualStyleBackColor = true;
            // 
            // label6
            // 
            this.label6.AutoSize = true;
            this.label6.Location = new System.Drawing.Point(13, 21);
            this.label6.Name = "label6";
            this.label6.Size = new System.Drawing.Size(87, 13);
            this.label6.TabIndex = 13;
            this.label6.Text = "Available Routes";
            // 
            // RunButton
            // 
            this.RunButton.Location = new System.Drawing.Point(347, 430);
            this.RunButton.Name = "RunButton";
            this.RunButton.Size = new System.Drawing.Size(85, 26);
            this.RunButton.TabIndex = 3;
            this.RunButton.Text = "Run";
            this.RunButton.UseVisualStyleBackColor = true;
            this.RunButton.Click += new System.EventHandler(this.RunButton_Click);
            // 
            // TreatmentGroup
            // 
            this.TreatmentGroup.Controls.Add(this.treatementsDataGridView);
            this.TreatmentGroup.Location = new System.Drawing.Point(617, 12);
            this.TreatmentGroup.Name = "TreatmentGroup";
            this.TreatmentGroup.Size = new System.Drawing.Size(696, 127);
            this.TreatmentGroup.TabIndex = 1;
            this.TreatmentGroup.TabStop = false;
            this.TreatmentGroup.Text = "Treatments";
            // 
            // treatementsDataGridView
            // 
            this.treatementsDataGridView.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            this.treatementsDataGridView.Columns.AddRange(new System.Windows.Forms.DataGridViewColumn[] {
            this.TreatmentIndex,
            this.TreatmentType,
            this.TreatmentMed,
            this.TreatmentQuantity,
            this.TreatmentUnits,
            this.TreatmentRoute});
            this.treatementsDataGridView.Dock = System.Windows.Forms.DockStyle.Fill;
            this.treatementsDataGridView.Location = new System.Drawing.Point(3, 16);
            this.treatementsDataGridView.Name = "treatementsDataGridView";
            this.treatementsDataGridView.RowHeadersVisible = false;
            this.treatementsDataGridView.Size = new System.Drawing.Size(690, 108);
            this.treatementsDataGridView.TabIndex = 0;
            // 
            // TreatmentIndex
            // 
            this.TreatmentIndex.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.Fill;
            this.TreatmentIndex.DataPropertyName = "index";
            this.TreatmentIndex.HeaderText = "Index";
            this.TreatmentIndex.Name = "TreatmentIndex";
            this.TreatmentIndex.ReadOnly = true;
            // 
            // TreatmentType
            // 
            this.TreatmentType.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.Fill;
            this.TreatmentType.DataPropertyName = "type";
            this.TreatmentType.HeaderText = "Type";
            this.TreatmentType.Name = "TreatmentType";
            this.TreatmentType.ReadOnly = true;
            // 
            // TreatmentMed
            // 
            this.TreatmentMed.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.Fill;
            this.TreatmentMed.DataPropertyName = "med";
            this.TreatmentMed.HeaderText = "Med";
            this.TreatmentMed.Name = "TreatmentMed";
            this.TreatmentMed.ReadOnly = true;
            // 
            // TreatmentQuantity
            // 
            this.TreatmentQuantity.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.Fill;
            this.TreatmentQuantity.DataPropertyName = "quantity";
            this.TreatmentQuantity.HeaderText = "Quantity";
            this.TreatmentQuantity.Name = "TreatmentQuantity";
            this.TreatmentQuantity.ReadOnly = true;
            // 
            // TreatmentUnits
            // 
            this.TreatmentUnits.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.Fill;
            this.TreatmentUnits.DataPropertyName = "units";
            this.TreatmentUnits.HeaderText = "Units";
            this.TreatmentUnits.Name = "TreatmentUnits";
            this.TreatmentUnits.ReadOnly = true;
            // 
            // TreatmentRoute
            // 
            this.TreatmentRoute.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.Fill;
            this.TreatmentRoute.DataPropertyName = "route";
            this.TreatmentRoute.HeaderText = "Route";
            this.TreatmentRoute.Name = "TreatmentRoute";
            this.TreatmentRoute.ReadOnly = true;
            // 
            // ReasoningGroup
            // 
            this.ReasoningGroup.Controls.Add(this.reasonsDataGridView);
            this.ReasoningGroup.Location = new System.Drawing.Point(617, 250);
            this.ReasoningGroup.Name = "ReasoningGroup";
            this.ReasoningGroup.Size = new System.Drawing.Size(693, 203);
            this.ReasoningGroup.TabIndex = 2;
            this.ReasoningGroup.TabStop = false;
            this.ReasoningGroup.Text = "Reasons";
            // 
            // reasonsDataGridView
            // 
            this.reasonsDataGridView.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            this.reasonsDataGridView.Columns.AddRange(new System.Windows.Forms.DataGridViewColumn[] {
            this.ReasonLevel,
            this.ReasonReason,
            this.Rule});
            this.reasonsDataGridView.Dock = System.Windows.Forms.DockStyle.Fill;
            this.reasonsDataGridView.Location = new System.Drawing.Point(3, 16);
            this.reasonsDataGridView.Name = "reasonsDataGridView";
            this.reasonsDataGridView.RowHeadersVisible = false;
            this.reasonsDataGridView.Size = new System.Drawing.Size(687, 184);
            this.reasonsDataGridView.TabIndex = 0;
            // 
            // ReasonLevel
            // 
            this.ReasonLevel.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.None;
            this.ReasonLevel.DataPropertyName = "level";
            this.ReasonLevel.FillWeight = 50.76142F;
            this.ReasonLevel.HeaderText = "Level";
            this.ReasonLevel.Name = "ReasonLevel";
            this.ReasonLevel.ReadOnly = true;
            this.ReasonLevel.Width = 50;
            // 
            // ReasonReason
            // 
            this.ReasonReason.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.Fill;
            this.ReasonReason.DataPropertyName = "text";
            this.ReasonReason.FillWeight = 149.2386F;
            this.ReasonReason.HeaderText = "Reason";
            this.ReasonReason.Name = "ReasonReason";
            this.ReasonReason.ReadOnly = true;
            // 
            // Rule
            // 
            this.Rule.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.None;
            this.Rule.DataPropertyName = "rule";
            this.Rule.HeaderText = "Rule";
            this.Rule.Name = "Rule";
            this.Rule.Visible = false;
            // 
            // ActionsGroup
            // 
            this.ActionsGroup.Controls.Add(this.actionsDataGridView);
            this.ActionsGroup.Location = new System.Drawing.Point(617, 145);
            this.ActionsGroup.Name = "ActionsGroup";
            this.ActionsGroup.Size = new System.Drawing.Size(696, 99);
            this.ActionsGroup.TabIndex = 3;
            this.ActionsGroup.TabStop = false;
            this.ActionsGroup.Text = "Actions";
            // 
            // actionsDataGridView
            // 
            this.actionsDataGridView.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            this.actionsDataGridView.Columns.AddRange(new System.Windows.Forms.DataGridViewColumn[] {
            this.ActionText});
            this.actionsDataGridView.Dock = System.Windows.Forms.DockStyle.Fill;
            this.actionsDataGridView.Location = new System.Drawing.Point(3, 16);
            this.actionsDataGridView.Name = "actionsDataGridView";
            this.actionsDataGridView.RowHeadersVisible = false;
            this.actionsDataGridView.Size = new System.Drawing.Size(690, 80);
            this.actionsDataGridView.TabIndex = 0;
            // 
            // ActionText
            // 
            this.ActionText.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.Fill;
            this.ActionText.DataPropertyName = "text";
            this.ActionText.HeaderText = "";
            this.ActionText.Name = "ActionText";
            this.ActionText.ReadOnly = true;
            // 
            // dataGridViewTextBoxColumn1
            // 
            this.dataGridViewTextBoxColumn1.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.AllCellsExceptHeader;
            this.dataGridViewTextBoxColumn1.DataPropertyName = "Value";
            this.dataGridViewTextBoxColumn1.HeaderText = "Value";
            this.dataGridViewTextBoxColumn1.Name = "dataGridViewTextBoxColumn1";
            this.dataGridViewTextBoxColumn1.Width = 5;
            // 
            // dataGridViewTextBoxColumn2
            // 
            this.dataGridViewTextBoxColumn2.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.Fill;
            this.dataGridViewTextBoxColumn2.DataPropertyName = "DT1";
            this.dataGridViewTextBoxColumn2.HeaderText = "DT1";
            this.dataGridViewTextBoxColumn2.Name = "dataGridViewTextBoxColumn2";
            // 
            // dataGridViewTextBoxColumn3
            // 
            this.dataGridViewTextBoxColumn3.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.Fill;
            this.dataGridViewTextBoxColumn3.DataPropertyName = "DT2";
            this.dataGridViewTextBoxColumn3.HeaderText = "DT2";
            this.dataGridViewTextBoxColumn3.Name = "dataGridViewTextBoxColumn3";
            // 
            // dataGridViewTextBoxColumn4
            // 
            this.dataGridViewTextBoxColumn4.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.Fill;
            this.dataGridViewTextBoxColumn4.DataPropertyName = "DT3";
            this.dataGridViewTextBoxColumn4.HeaderText = "DT3";
            this.dataGridViewTextBoxColumn4.Name = "dataGridViewTextBoxColumn4";
            // 
            // dataGridViewTextBoxColumn5
            // 
            this.dataGridViewTextBoxColumn5.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.Fill;
            this.dataGridViewTextBoxColumn5.DataPropertyName = "DT4";
            this.dataGridViewTextBoxColumn5.HeaderText = "DT4";
            this.dataGridViewTextBoxColumn5.Name = "dataGridViewTextBoxColumn5";
            // 
            // dataGridViewTextBoxColumn6
            // 
            this.dataGridViewTextBoxColumn6.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.Fill;
            this.dataGridViewTextBoxColumn6.DataPropertyName = "DT5";
            this.dataGridViewTextBoxColumn6.HeaderText = "DT5";
            this.dataGridViewTextBoxColumn6.Name = "dataGridViewTextBoxColumn6";
            // 
            // TopForm
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(1318, 464);
            this.Controls.Add(this.ActionsGroup);
            this.Controls.Add(this.ReasoningGroup);
            this.Controls.Add(this.TreatmentGroup);
            this.Controls.Add(this.InputDataGroup);
            this.Name = "TopForm";
            this.InputDataGroup.ResumeLayout(false);
            this.InputDataGroup.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.medsDataGridView)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.valuesDataGridView)).EndInit();
            this.TreatmentGroup.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.treatementsDataGridView)).EndInit();
            this.ReasoningGroup.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.reasonsDataGridView)).EndInit();
            this.ActionsGroup.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.actionsDataGridView)).EndInit();
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.GroupBox InputDataGroup;
        private System.Windows.Forms.GroupBox TreatmentGroup;
        private System.Windows.Forms.GroupBox ReasoningGroup;
        private System.Windows.Forms.Button RunButton;
        private System.Windows.Forms.DataGridView treatementsDataGridView;
        private System.Windows.Forms.DataGridView reasonsDataGridView;
        private System.Windows.Forms.GroupBox ActionsGroup;
        private System.Windows.Forms.DataGridView actionsDataGridView;
        private System.Windows.Forms.DataGridViewTextBoxColumn TreatmentIndex;
        private System.Windows.Forms.DataGridViewTextBoxColumn TreatmentType;
        private System.Windows.Forms.DataGridViewTextBoxColumn TreatmentMed;
        private System.Windows.Forms.DataGridViewTextBoxColumn TreatmentQuantity;
        private System.Windows.Forms.DataGridViewTextBoxColumn TreatmentUnits;
        private System.Windows.Forms.DataGridViewTextBoxColumn TreatmentRoute;
        private System.Windows.Forms.DataGridViewTextBoxColumn ActionText;
        private System.Windows.Forms.Label label6;
        private System.Windows.Forms.CheckBox peripheralIvRouteCheckBox;
        private System.Windows.Forms.CheckBox centralIvRouteCheckBox;
        private System.Windows.Forms.CheckBox enteralRouteCheckBox;
        private System.Windows.Forms.DataGridViewTextBoxColumn ReasonLevel;
        private System.Windows.Forms.DataGridViewTextBoxColumn ReasonReason;
        private System.Windows.Forms.DataGridViewTextBoxColumn Rule;
        private System.Windows.Forms.DataGridView valuesDataGridView;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.DataGridViewTextBoxColumn Value;
        private System.Windows.Forms.DataGridViewTextBoxColumn DT1;
        private System.Windows.Forms.DataGridViewTextBoxColumn DT2;
        private System.Windows.Forms.DataGridViewTextBoxColumn DT3;
        private System.Windows.Forms.DataGridViewTextBoxColumn DT4;
        private System.Windows.Forms.DataGridViewTextBoxColumn DT5;
        private System.Windows.Forms.Button SaveButton;
        private System.Windows.Forms.Button LoadButton;
        private System.Windows.Forms.DataGridView medsDataGridView;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.DataGridViewTextBoxColumn dataGridViewTextBoxColumn1;
        private System.Windows.Forms.DataGridViewTextBoxColumn dataGridViewTextBoxColumn2;
        private System.Windows.Forms.DataGridViewTextBoxColumn dataGridViewTextBoxColumn3;
        private System.Windows.Forms.DataGridViewTextBoxColumn dataGridViewTextBoxColumn4;
        private System.Windows.Forms.DataGridViewTextBoxColumn dataGridViewTextBoxColumn5;
        private System.Windows.Forms.DataGridViewTextBoxColumn dataGridViewTextBoxColumn6;
    }
}

