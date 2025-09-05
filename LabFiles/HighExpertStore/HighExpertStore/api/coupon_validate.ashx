<%@ WebHandler Language="C#" Class="ApiCouponValidate" %>
using System;using System.Data.SqlClient;using System.Web;using HighExpertStore;
public class ApiCouponValidate:IHttpHandler{
public void ProcessRequest(HttpContext c){c.Response.ContentType="application/json";try{
string code=(c.Request["code"]??"").Trim().ToUpperInvariant();if(string.IsNullOrEmpty(code)){c.Response.StatusCode=400;c.Response.Write(Db.Json(new{error="Informe o código"}));return;}
using(var conn=Db.GetConnection()){conn.Open();using(var cmd=new SqlCommand(@"SELECT Code,DiscountType,DiscountValue,Active,ExpiresAt FROM Coupons WHERE Code=@c",conn)){cmd.Parameters.AddWithValue("@c",code);
using(var r=cmd.ExecuteReader()){if(!r.Read()){c.Response.StatusCode=404;c.Response.Write(Db.Json(new{error="Cupom não encontrado"}));return;}var active=r.GetBoolean(3);if(!active){c.Response.StatusCode=400;c.Response.Write(Db.Json(new{error="Cupom inativo"}));return;}if(!r.IsDBNull(4)&&r.GetDateTime(4)<DateTime.UtcNow){c.Response.StatusCode=400;c.Response.Write(Db.Json(new{error="Cupom expirado"}));return;}
c.Response.Write(Db.Json(new{code=r.GetString(0),type=r.GetString(1),value=Math.Round(r.GetDecimal(2),2)}));}}}}catch(Exception ex){c.Response.StatusCode=500;c.Response.Write(Db.Json(new{error=ex.Message}));}}public bool IsReusable{get{return false;}}}