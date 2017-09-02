function [RJ,RL,rJ,rL,e,g]=Kinematics(R0,r0,qm,robot)
% Computes the kinematics of the multibody system.
%
% [RJ,RL,rJ,rL,e,g]=Kinematics(R0,r0,qm,robot)
%
% :parameters: 
%   * R0 -- Rotation matrix from the base-spacecraft to the inertial frame -- [3x3].
%   * r0 -- Position of the base-spacecraft with respect to the inertial frame -- [3x1].
%   * qm -- Manipulator joint varibles -- [n_qx1].
%   * robot -- Robot model (see :doc:`/Robot_Model`).
%
% :return: 
%   * RJ -- Joint rotation matrices -- [3x3xn].
%   * RL -- Links rotation matrices -- [3x3xn].
%   * rJ -- Joints positions -- [3xn].
%   * rL -- Links center-of-mass positions -- [3xn].
%   * e -- Joints rotation/sliding axis -- [3xn].
%   * g -- Vector from the origin of the ith joint to the ith link -- [3xn].
%
% All the ouput magnitudes are expressed in the **inertial frame**.
%
% Examples:
%
%   Retrieving the position of the ith link: ``rL(1:3,i)``.
%
%   Retrieving the rotation matrix of the ith joint: ``RJ(1:3,1:3,i)``.   
%
% See also: :func:`src.robot_model.urdf2robot` and :func:`src.robot_model.DH_Serial2robot`.

%{  
    LICENSE

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
%}

%=== CODE ===%

%--- Number of links and joints ---%
n=robot.n_links_joints;

%--- Homogeneous transformation matrices ---%

%Pre-allocate homogeneous transformations matrices
TJ=zeros(4,4,n,'like',R0);
TL=zeros(4,4,n,'like',R0);

%--- Base link ---%
clink = robot.base_link;
T0=[R0,r0;zeros(1,3),1]*clink.T;

%--- Forward kinematics recursion ---%
%Obtain of joints and links kinematics
for i=1:n
    
    %Get child joint
    cjoint=robot.joints(i);
    
    %Joint kinematics
    if cjoint.parent_link==0
        %Parent link is base link
        TJ(1:4,1:4,cjoint.id)=T0*cjoint.T;
    else
        %Joint kinematics
        TJ(1:4,1:4,cjoint.id)=TL(1:4,1:4,cjoint.parent_link)*cjoint.T;
    end
    
    %Transformation due to current joint variable
    if cjoint.type==1
        T_qm=[Euler_DCM(cjoint.axis,qm(cjoint.q_id))',zeros(3,1);zeros(1,3),1];
    elseif cjoint.type==2
        T_qm=[eye(3),cjoint.axis*qm(cjoint.q_id);zeros(1,3),1];
    else
        T_qm=[eye(3),zeros(3,1);zeros(1,3),1];
    end
    
    %Link Kinematics
    clink=robot.links(cjoint.child_link);
    TL(1:4,1:4,clink.id)=TJ(1:4,1:4,clink.parent_joint)*T_qm*clink.T;
end

%--- Rotation matrices, translation, position and other geometry vectors ---%

%Pre-allocate rotation matrices, translation and position vectors
RJ=zeros(3,3,n,'like',R0);
RL=zeros(3,3,n,'like',R0);
rJ=zeros(3,n,'like',R0);
rL=zeros(3,n,'like',R0);
%Pre-allocate rotation/sliding axis
e=zeros(3,n,'like',R0);
%Pre-allocate other gemotery vectors
g=zeros(3,n,'like',R0);

%Format Rotation matrices, link positions, joint axis and other geometry
%vectors
%Joint associated quantities
for i=1:n
    RJ(1:3,1:3,i)=TJ(1:3,1:3,i);
    rJ(1:3,i)=TJ(1:3,4,i);
    e(1:3,i)=RJ(1:3,1:3,i)*robot.joints(i).axis;
end
%Link associated quantities
for i=1:n
    RL(1:3,1:3,i)=TL(1:3,1:3,i);
    rL(1:3,i)=TL(1:3,4,i);
    g(1:3,i)=rL(1:3,i)-rJ(1:3,robot.links(i).parent_joint);
end


end