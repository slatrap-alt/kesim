from pathlib import Path

path = Path("index.html")
html = path.read_text(encoding="utf-8")

def replace_once(old: str, new: str, label: str) -> None:
    global html
    count = html.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected exactly one match, found {count}; deployment stopped safely.")
    html = html.replace(old, new, 1)

replace_once(
    "${payment?'':`<label>Tedarikçi (cari hesaba aktar)<select id=\"ce_supplier\">${supplierOptions()}</select><small>Seçtiğin tedarikçinin cari hesabına otomatik borç olarak işlenir.</small></label>`}",
    "`<label>${payment?'Tedarikçi (cari hesaptan düş)':'Tedarikçi (cari hesaba aktar)'}<select id=\"ce_supplier\">${supplierOptions()}</select><small>${payment?'Tedarikçi seçersen bu ödeme, seçtiğin firmanın cari borcundan düşülür.':'Seçtiğin tedarikçinin cari hesabına otomatik borç olarak işlenir.'}</small></label>`",
    "payment supplier selector"
)
replace_once(
    "${!payment&&x.supplierId?`<small class=\"entry-supplier\" data-entry-supplier=\"${safe(x.supplierId)}\">Cari: ${safe(supplierDirectory.find(s=>s.id===x.supplierId)?.name||'Tedarikçi')}</small>`:''}",
    "${x.supplierId?`<small class=\"entry-supplier\" data-entry-supplier=\"${safe(x.supplierId)}\">${payment?'Cari hesaptan düşüldü: ':'Cari borç eklendi: '}${safe(supplierDirectory.find(s=>s.id===x.supplierId)?.name||'Tedarikçi')}</small>`:''}",
    "supplier display in movement list"
)
replace_once(
    "if(activeTab==='expenses'&&q('ce_supplier')?.value)entry.supplierId=q('ce_supplier').value;",
    "if(q('ce_supplier')?.value)entry.supplierId=q('ce_supplier').value;",
    "save supplier on payment and expense"
)
replace_once(
    "q('le_supplier').innerHTML=supplierOptions(entry.supplierId||'');q('ledgerEditSupplierWrap').hidden=tab!=='expenses';q('ledgerEditMethod').hidden=tab!=='payments';",
    "q('le_supplier').innerHTML=supplierOptions(entry.supplierId||'');q('ledgerEditSupplierWrap').hidden=false;if(q('ledgerEditSupplierWrap').firstChild)q('ledgerEditSupplierWrap').firstChild.textContent=tab==='payments'?'Tedarikçi (cari hesaptan düş)':'Tedarikçi (cari hesaba aktar)';q('ledgerEditMethod').hidden=tab!=='payments';",
    "supplier selector in edit dialog"
)
replace_once(
    "if(edit.kind==='expenses'){const supplierId=q('le_supplier').value;if(supplierId)next.supplierId=supplierId;else delete next.supplierId}if(edit.kind==='payments'){const method=q('le_method').value;if(method)next.method=method;else delete next.method}",
    "{const supplierId=q('le_supplier').value;if(supplierId)next.supplierId=supplierId;else delete next.supplierId}if(edit.kind==='payments'){const method=q('le_method').value;if(method)next.method=method;else delete next.method}",
    "save supplier when editing payment"
)

path.write_text(html, encoding="utf-8")
print("Supplier payment integration applied.")
