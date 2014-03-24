import haxe.io.Path;
import sys.FileSystem;

class FileGroup
{
   public function new(inDir:String,inId:String)
   {
      mNewest = 0;
      mFiles = [];
      mCompilerFlags = [];
      mPrecompiledHeader = "";
      mDepends = [];
      mMissingDepends = [];
      mOptions = [];
      mHLSLs = [];
      mDir = inDir;
      mId = inId;
   }

   public function preBuild()
   {
      for(hlsl in mHLSLs)
         hlsl.build();

      if (BuildTool.useCache)
      {
         mDependHash = "";
         for(depend in mDepends)
            mDependHash += File.getFileHash(depend);
         mDependHash = haxe.crypto.Md5.encode(mDependHash);
      }
   }

   public function addHLSL(inFile:String,inProfile:String,inVariable:String,inTarget:String)
   {
      addDepend(inFile);

      mHLSLs.push( new HLSL(inFile,inProfile,inVariable,inTarget) );
   }


   public function addDepend(inFile:String)
   {
      if (!FileSystem.exists(inFile))
      {
         mMissingDepends.push(inFile);
         return;
      }
      var stamp =  FileSystem.stat(inFile).mtime.getTime();
      if (stamp>mNewest)
         mNewest = stamp;

      mDepends.push(inFile);
   }


   public function addOptions(inFile:String)
   {
      mOptions.push(inFile);
   }

   public function getPchDir()
   {
      return "__pch/" + mId ;
   }

   public function checkOptions(inObjDir:String)
   {
      var changed = false;
      for(option in mOptions)
      {
         if (!FileSystem.exists(option))
         {
            mMissingDepends.push(option);
         }
         else
         {
            var contents = sys.io.File.getContent(option);

            var dest = inObjDir + "/" + haxe.io.Path.withoutDirectory(option);
            var skip = false;

            if (FileSystem.exists(dest))
            {
               var dest_content = sys.io.File.getContent(dest);
               if (dest_content==contents)
                  skip = true;
            }
            if (!skip)
            {
               DirManager.make(inObjDir);
               var stream = sys.io.File.write(dest,true);
               stream.writeString(contents);
               stream.close();
               changed = true;
            }
            addDepend(dest);
         }
      }
      return changed;
   }

   public function checkDependsExist()
   {
      if (mMissingDepends.length>0)
         throw "Could not find dependencies: " + mMissingDepends.join(",");
   }

   public function addCompilerFlag(inFlag:String)
   {
      mCompilerFlags.push(inFlag);
   }

   public function isOutOfDate(inStamp:Float)
   {
      return inStamp<mNewest;
   }

   public function setPrecompiled(inFile:String, inDir:String)
   {
      mPrecompiledHeader = inFile;
      mPrecompiledHeaderDir = inDir;
   }
   public function getPchName()
   {
      return Path.withoutDirectory(mPrecompiledHeader);
   }


   public var mNewest:Float;
   public var mCompilerFlags:Array<String>;
   public var mMissingDepends:Array<String>;
   public var mOptions:Array<String>;
   public var mPrecompiledHeader:String;
   public var mPrecompiledHeaderDir:String;
   public var mFiles: Array<File>;
   public var mHLSLs: Array<HLSL>;
   public var mDir : String;
   public var mId : String;
   public var mDepends:Array<String>;
   public var mDependHash : String;
}