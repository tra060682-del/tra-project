export const formatInr=(paise:number|null)=>paise===null?'Awaiting first bid':new Intl.NumberFormat('en-IN',{style:'currency',currency:'INR',maximumFractionDigits:0}).format(paise/100);
