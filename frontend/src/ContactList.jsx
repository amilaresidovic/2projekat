import React from "react";
import { deleteContact } from "./api";

const ContactList = ({ contacts, updateContact, updateCallback }) => {
  const onDelete = async (id) => {
    try {
      await deleteContact(id);
      updateCallback();
    } catch (error) {
      alert("Failed to delete contact");
    }
  };

  return (
    <div>
      <h2>Contacts</h2>
      <table>
        <thead>
          <tr>
            <th>First Name</th><th>Last Name</th><th>Email</th><th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {contacts.map((contact) => (
            <tr key={contact.id}>
              <td>{contact.firstName}</td>
              <td>{contact.lastName}</td>
              <td>{contact.email}</td>
              <td>
                <button onClick={() => updateContact(contact)}>Update</button>
                <button onClick={() => onDelete(contact.id)}>Delete</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default ContactList;