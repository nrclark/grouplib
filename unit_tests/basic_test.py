#!/usr/bin/env python

import shutil
import random
import md5
import unittest
import os
import subprocess

def sanitize(path):
    path = os.path.expanduser(path)
    path = os.path.expandvars(path)
    path = os.path.normpath(path)
    path = os.path.abspath(path)
    return path

def run_make(Makefile=None, targets=None, flags=None, dir='.'):
    dir = sanitize(dir)
    cmd = ['make']
    
    if Makefile != None:
        Makefile = sanitize(Makefile)
        cmd = cmd + ['-f', Makefile]
    
    if targets != None:
        if type(targets) == str:
            targets = targets.split(' ') 
        if type(targets) != list:
            raise ValueError, 'targets could not be determined from '+str(targets)
        targets = [x.strip() for x in targets]
            
        cmd = cmd + targets
    
    if flags != None:
        if type(flags) == str:
            flags = flags.split(' ')
        if type(flags) != list:
            raise ValueError, 'flags could not be determined from '+str(flags)

        flags = [x.strip() for x in flags]
        cmd = cmd + flags

    p = subprocess.Popen(cmd, cwd=dir, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = p.communicate()
    return p.returncode, stdout, stderr

def create_source(filename, dir='.'):
    string = os.path.basename(filename)
    myFile = open(os.path.join(dir, filename), 'w')
    myFile.write(string + '\n')
    myFile.close()

class MakeTest(unittest.TestCase):
    def setUp(self, Makefile, groupLib):
        self.Makefile = sanitize(Makefile)
        self.groupLib = sanitize(groupLib)
        self.assertTrue(os.path.isfile(self.Makefile))
        self.assertTrue(os.path.isfile(self.groupLib))
        self.workDir = '_tmp_' + md5.new(str(random.random())).hexdigest()
        os.mkdir(self.workDir)
        shutil.copy2(self.groupLib, self.workDir)
        shutil.copy2(self.Makefile, os.path.join(self.workDir, 'Makefile'))        

    def tearDown(self):
        shutil.rmtree(self.workDir)

class TestBasicOperation(MakeTest):
    def setUp(self):
        super(TestBasicOperation, self).setUp('case_01.mk', '../grouplib.mk')
        create_source('source.1', self.workDir)
        create_source('source.2', self.workDir)

    def test_Simple(self):
        retval, stdout, stderr = run_make(dir=self.workDir)
        print retval
        print stdout
        print stderr

        
if __name__ == '__main__':
    unittest.main()
