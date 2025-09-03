<%@ WebHandler Language="C#" Class="ApiAuthLogin" %>
using System;using System.Data.SqlClient;using System.Web;using HighExpertStore;
public class ApiAuthLogin:IHttpHandler{
public void ProcessRequest(HttpContext c){c.Response.ContentType="application/json";try{
var body=Db.ReadBody(c.Request);dynamic p=new System.Web.Script.Serialization.JavaScriptSerializer().DeserializeObject(body);
string email=p.ContainsKey("email")?(string)p["email"]:"",password=p.ContainsKey("password")?(string)p["password"]:"";
if(string.IsNullOrWhiteSpace(email)||string.IsNullOrWhiteSpace(password)){c.Response.StatusCode=400;c.Response.Write(Db.Json(new{error="Campos obrigatórios: email, password"}));return;}
using(var conn=Db.GetConnection()){conn.Open();int uid=0;string name="",hb=null,sb=null;using(var cmd=new SqlCommand("SELECT Id,Name,PasswordHash,PasswordSalt FROM Users WHERE Email=@e",conn)){cmd.Parameters.AddWithValue("@e",email);using(var r=cmd.ExecuteReader()){if(!r.Read()){c.Response.StatusCode=401;c.Response.Write(Db.Json(new{error="Credenciais inválidas"}));return;}uid=r.GetInt32(0);name=r.GetString(1);hb=r.GetString(2);sb=r.GetString(3);}}
var salt=Db.FromBase64(sb);var hash=Db.HashPassword(password,salt);if(Db.ToBase64(hash)!=hb){c.Response.StatusCode=401;c.Response.Write(Db.Json(new{error="Credenciais inválidas"}));return;}
var tok=Db.NewToken();using(var s=new SqlCommand(@"INSERT INTO Sessions(Token,UserId,CreatedAt,ExpiresAt) VALUES(@t,@u,SYSUTCDATETIME(),DATEADD(day,7,SYSUTCDATETIME()))",conn)){s.Parameters.AddWithValue("@t",tok);s.Parameters.AddWithValue("@u",uid);s.ExecuteNonQuery();}
c.Response.Write(Db.Json(new{token=tok.ToString(),user=new{id=uid,name=name,email=email}}));}}catch(Exception ex){c.Response.StatusCode=500;c.Response.Write(Db.Json(new{error=ex.Message}));}}public bool IsReusable{get{return false;}}}