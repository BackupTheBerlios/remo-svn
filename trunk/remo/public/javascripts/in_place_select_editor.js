Ajax.InPlaceSelectEditor = Class.create();
Object.extend(Object.extend(Ajax.InPlaceSelectEditor.prototype,
                            Ajax.InPlaceEditor.prototype), {
    createEditField: function() {
        var text;
        if(this.options.loadTextURL) {
            text = this.options.loadingText;
        } else {
            text = this.getText();
        }

        this.options.textarea = false;

        var selectField = document.createElement("select");
        selectField.name = "value";
        var options=this.options.selectOptionsHTML;        
        for (var x=0; x<options.length; x++)
        {
            var option = document.createElement("option");
            option.appendChild(document.createTextNode(options[x]));
            option.setAttribute("value",options[x]);
            selectField.appendChild(option);
        }

        $A(selectField.options).each(function(opt, index){
            if(text == opt.value) {
                selectField.selectedIndex = index;
            }
        }
    );

        selectField.style.backgroundColor = this.options.highlightcolor;
        this.editField = selectField;
        if(this.options.loadTextURL) {
          this.loadExternalText();
        }
        this.form.appendChild(this.editField);
    }
});
